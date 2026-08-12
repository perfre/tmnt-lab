# ops_mariadb

Reconciles the MariaDB databases, users, and grants declared under `ops_mariadb`. The role is idempotent and does not delete unlisted resources. Set `state: absent` explicitly for a deliberate removal.

```yaml
ops_mariadb:
  login_host: 127.0.0.1
  login_password: LAB_ONLY_MARIADB_ADMIN_PASSWORD_DO_NOT_REUSE
  databases:
    - name: application
  users:
    - name: application
      host: "%"
      password: LAB_ONLY_APPLICATION_MARIADB_PASSWORD_DO_NOT_REUSE
      privileges:
        "application.*": ALL
```

This role installs the target host's PyMySQL package. The committed local inventory connects through the loopback-only administrative port owned by `docker_mariadb`; that port is published through the separate `tmnt_mariadb_admin` network while application consumers stay on the internal `tmnt_mariadb` network. Non-loopback operation requires `tls.enabled: true`, a CA certificate, hostname checking, and secrets from Vault or another protected source. Run it after the database runtime role.
