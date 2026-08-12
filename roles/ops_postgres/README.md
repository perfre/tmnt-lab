# ops_postgres

Reconciles the PostgreSQL users and databases declared under `ops_postgres`. Users are created first so each database can be assigned its declared owner. The role does not delete unlisted resources; set `state: absent` explicitly for a deliberate removal.

```yaml
ops_postgres:
  login_host: 127.0.0.1
  login_password: LAB_ONLY_POSTGRES_ADMIN_PASSWORD_DO_NOT_REUSE
  ssl_mode: disable
  users:
    - name: application
      password: LAB_ONLY_APPLICATION_POSTGRES_PASSWORD_DO_NOT_REUSE
  databases:
    - name: application
      owner: application
```

This role installs the target host's Psycopg driver package. The committed local inventory connects through the loopback-only administrative port owned by `docker_postgres`; that port is published through the separate `tmnt_postgres_admin` network while application consumers stay on the internal `tmnt_postgres` network. Non-loopback operation requires `ssl_mode: verify-full`, a CA certificate under `tls.ca_cert`, and secrets from Vault or another protected source. Run it after the database runtime role.
