<!--
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2020-2024 MDAD project contributors
SPDX-FileCopyrightText: 2020-2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Julian-Samuel Gebühr
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024 Thomas Miceli
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up CodiMD

This is an [Ansible](https://www.ansible.com/) role which installs [CodiMD](https://github.com/hackmdio/codimd) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

CodiMD is a realtime collaborative markdown notes on all platforms.

See the project's [documentation](https://hackmd.io/c/codimd-documentation) to learn what CodiMD does and why it might be useful to you.

## Prerequisites

To run a CodiMD instance it is necessary to prepare a database. You can use a [MySQL](https://www.mysql.com/) compatible database server or [Postgres](https://www.postgresql.org/).

If you are looking for Ansible roles for a MySQL compatible server or Postgres, you can check out [ansible-role-mariadb](https://github.com/mother-of-all-self-hosting/ansible-role-mariadb) and [ansible-role-postgres](https://github.com/mother-of-all-self-hosting/ansible-role-postgres), both of which are maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team.

## Adjusting the playbook configuration

To enable CodiMD with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# codimd                                                               #
#                                                                      #
########################################################################

codimd_enabled: true

########################################################################
#                                                                      #
# /codimd                                                              #
#                                                                      #
########################################################################
```

### Set the hostname

To enable CodiMD you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
codimd_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting CodiMD under a subpath (by configuring the `codimd_path_prefix` variable) does not seem to be possible due to CodiMD's technical limitations.

### Specify database

It is necessary to select database used by CodiMD from a MySQL compatible database and Postgres.

To use Postgres, add the following configuration to your `vars.yml` file:

```yaml
codimd_database_type: postgres
```

Set `mysql` to use a MySQL compatible database.

For other settings, check variables such as `codimd_database_*` on [`defaults/main.yml`](../defaults/main.yml).

### Set a random string for signing cookie

You also need to set a random string for signing the session cookie. To do so, add the following configuration to your `vars.yml` file. The value can be generated with `pwgen -s 64 1` or in another way.

```yaml
codimd_environment_variables_cmd_session_secret: YOUR_SECRET_KEY_HERE
```

### Enabling account registration

To use CodiMD you need to create an account and log in to it on the browser.

In order to prevent abuse, account registration is disabled by default. You can enable account registration and authentication with an email address by adding the following configuration to your `vars.yml` file:

```yaml
# Control if email sign-in is allowed
codimd_environment_variables_cmd_email: true

# Control if email registration is allowed
codimd_environment_variables_cmd_allow_email_register: true
```

>[!NOTE]
> The email address verification with an email server is not available.

Refer to [this section](https://hackmd.io/c/codimd-documentation/%2Fs%2Fcodimd-configuration#Authentication) on the official documentation for details about setting up other authentication system like LDAP and OAuth.

### Configuring default permission (optional)

It is possible to change the default access permission to a note by adding the following configuration to your `vars.yml` file:

```yaml
# Valid values: editable, freely, limited, locked, private, protected
codimd_environment_variables_cmd_default_permission: PERMISSION_STRING_HERE
```

Refer to [this section](https://hackmd.io/@codimd/note-permission#Manage-Note-Permission) on the official documentation for details about the permissions.

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `codimd_environment_variables_additional_variables` variable

Refer to [the official documentation](https://hackmd.io/c/codimd-documentation/%2Fs%2Fcodimd-configuration) for a complete list of CodiMD's config options that you can put in `codimd_environment_variables_additional_variables`.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, CodiMD becomes available at the specified hostname like `https://example.com`.

To get started, open the URL with a web browser to log in to the instance, if anonymous usage is disallowed (which is the default setting).

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu codimd` (or how you/your playbook named the service, e.g. `mash-codimd`).
