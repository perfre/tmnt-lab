# ops_mariadb

Reconciles the MariaDB databases, users, and grants declared under `ops_mariadb`. The role is idempotent and does not delete unlisted resources. Set `state: absent` explicitly for a deliberate removal.

```yaml
ops_mariadb:
  databases:
    - name: application
  users:
    - name: application
      host: "%"
      password: LAB_ONLY_APPLICATION_MARIADB_PASSWORD_DO_NOT_REUSE
      privileges:
        "application.*": ALL
```

This version is localhost-lab only and installs the target host's PyMySQL package. It connects through the loopback-only port owned by `docker_mariadb`. Run it after that role. Production use requires Vault or an approved secret source plus verified MariaDB TLS.
