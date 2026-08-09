# ops_postgres

Reconciles the PostgreSQL users and databases declared under `ops_postgres`. Users are created first so each database can be assigned its declared owner. The role does not delete unlisted resources; set `state: absent` explicitly for a deliberate removal.

```yaml
ops_postgres:
  users:
    - name: application
      password: LAB_ONLY_APPLICATION_POSTGRES_PASSWORD_DO_NOT_REUSE
  databases:
    - name: application
      owner: application
```

This version is localhost-lab only and installs the target host's Psycopg driver package. It connects through the loopback-only administrative port owned by `docker_postgres`; that port is published through the separate `tmnt_postgres_admin` network while application consumers stay on the internal `tmnt_postgres` network. Run it after that role. Production use requires Vault or an approved secret source plus verified PostgreSQL TLS.
