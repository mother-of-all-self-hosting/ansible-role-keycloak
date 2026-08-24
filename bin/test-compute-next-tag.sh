#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the
# real script, tagging as it goes just like the autotag workflow does. This
# repository is never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# Starts a scenario with a repository at Keycloak 26.7.1 which has already
# seen two releases of it (v26.7.1-0 and v26.7.1-1).
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/tasks" "$workdir/templates" "$workdir/vars" "$workdir/molecule/default"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	# The decoy lines are ones that really do sit around `keycloak_version` in
	# the role: a commented-out override and a variable that interpolates it.
	# Neither may be mistaken for the version itself.
	cat > defaults/main.yml <<-'EOF'
		# keycloak_version: 9.9.9
		keycloak_version: 26.7.1
		keycloak_container_image_tag: "{{ keycloak_version }}"
	EOF
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > vars/main.yml
	printf 'placeholder\n' > molecule/default/verify.yml
	printf 'placeholder\n' > README.md

	git add -A
	git commit -qm 'Initial commit'

	local release_number
	for release_number in 0 1; do
		git tag "v26.7.1-$release_number"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version="sed -i 's|keycloak_version: 26.7.1|keycloak_version: 26.7.2|' defaults/main.yml"
revert_version="sed -i 's|keycloak_version: 26.7.2|keycloak_version: 26.7.1|' defaults/main.yml"
quote_version="sed -i 's|keycloak_version: 26.7.1|keycloak_version: \"26.7.3\"|' defaults/main.yml"
annotate_version="sed -i '1i # renovate: datasource=docker depName=quay.io/keycloak/keycloak versioning=semver' defaults/main.yml"
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_vars="printf 'a fact\n' >> vars/main.yml"
edit_molecule="printf 'a check\n' >> molecule/default/verify.yml"
edit_readme="printf 'documentation\n' >> README.md"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with
# every update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v26.7.2-0 "$(merge "$bump_version")"
expect 'task edit'    v26.7.2-1 "$(merge "$edit_task")"
expect 'template'     v26.7.2-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v26.7.1-2 "$(merge "$edit_task")"
expect 'version bump' v26.7.2-0 "$(merge "$bump_version")"

# `vars/` holds the log-level list that the env file is rendered from, so a
# change there reaches the running container and has to be released.
scenario 'A change under vars/'
expect 'vars edit' v26.7.1-2 "$(merge "$edit_vars")"

scenario 'Commits that do not affect the role'
expect 'README'      ''         "$(merge "$edit_readme")"
expect 'a script'    ''         "$(merge "$edit_script")"
expect 'Molecule'    ''         "$(merge "$edit_molecule")"
expect 'a task'      v26.7.1-2  "$(merge "$edit_task")"

# Renovate writes the version unquoted today, but the annotation comment above
# it and a quoted value are both things a human might introduce by hand.
#
# The annotation is a comment, yet it lands in defaults/main.yml and therefore
# releases: the script deliberately does not try to judge whether a change to a
# role-defining file is meaningful, and treating comments as exempt would mean
# guessing.
scenario 'A quoted version, under a Renovate annotation'
expect 'annotation'     v26.7.1-2  "$(merge "$annotate_version")"
expect 'quoted version' v26.7.3-0  "$(merge "$quote_version")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v26.7.1-$release_number"
done
expect 'a task' v26.7.1-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v26.7.1-1 already published, so there is
# nothing new to release.
expect 'a revert' '' "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v26.7.1-2 "$(merge "$revert_version && $edit_task")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
