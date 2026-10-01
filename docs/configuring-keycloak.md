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

# Setting up Keycloak

This is an [Ansible](https://www.ansible.com/) role which installs [Keycloak](https://www.keycloak.org) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Keycloak is an open-source identity and access management solution.

See the project's [documentation](https://www.keycloak.org/documentation) to learn what Keycloak does and why it might be useful to you.

## Prerequisites

To run a Keycloak instance it is necessary to prepare a database. You can use a [MySQL](https://www.mysql.com/) compatible database server, [Postgres](https://www.postgresql.org/), MS SQL, or Oracle.

If you are looking for Ansible roles for a MySQL compatible server or Postgres, you can check out [ansible-role-mariadb](https://github.com/mother-of-all-self-hosting/ansible-role-mariadb) and [ansible-role-postgres](https://github.com/mother-of-all-self-hosting/ansible-role-postgres), both of which are maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team.

## Adjusting the playbook configuration

To enable Keycloak with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# keycloak                                                             #
#                                                                      #
########################################################################

keycloak_enabled: true

########################################################################
#                                                                      #
# /keycloak                                                            #
#                                                                      #
########################################################################
```

### Set the hostname

To enable Keycloak you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
keycloak_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

### Specify database

You can specify a database used by Keycloak. By default it is configured to use Postgres.

To use MariaDB, add the following configuration to your `vars.yml` file:

```yaml
keycloak_database_type: mariadb
```

Set `mysql` for MySQL, `mssql` for MS SQL, or `oracle` for Oracle, respectively.

For other settings, check variables such as `keycloak_database_*` on [`defaults/main.yml`](../defaults/main.yml).

### Set details for the admin user

You also need to create an instance's admin user. To create one, add the following configuration to your `vars.yml` file. Make sure to replace values with your own ones.

```yaml
keycloak_environment_variable_kc_bootstrap_admin_username: ADMIN_USERNAME_HERE
keycloak_environment_variable_kc_bootstrap_admin_password: ADMIN_PASSWORD_HERE
```

Generating a strong password (e.g. `pwgen -s 64 1`) is recommended for `keycloak_environment_variable_kc_bootstrap_admin_password`.

>[!NOTE]
>
> - On each start after that, Keycloak will attempt to create the user again and report a non-fatal error (Keycloak will continue running).
> - Subsequent changes to the password will not affect an existing user's password.

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `keycloak_environment_variables_additional_variables` variable

Refer to [the official documentation](https://www.keycloak.org/server/all-config) for a complete list of Keycloak's config options that you can put in `keycloak_environment_variables_additional_variables`.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Keycloak becomes available at the specified hostname like `https://example.com`.

To get started, open the URL with a web browser to log in to the instance with the administrator account. The account is created on the first start, as defined with the `keycloak_environment_variable_kc_bootstrap_admin_username` and `keycloak_environment_variable_kc_bootstrap_admin_password` variables.

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu keycloak` (or how you/your playbook named the service, e.g. `mash-keycloak`).
