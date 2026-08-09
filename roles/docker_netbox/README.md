# docker_netbox

Runs NetBox with Valkey using Docker Compose. PostgreSQL is an external dependency owned by `docker_postgres`; its database and application user are owned by `ops_postgres`.

All inventory/default configuration lives under `docker_netbox`.

```yaml
docker_netbox:
  project_dir: /opt/docker/netbox
  image: docker.io/netboxcommunity/netbox:v4.6-5.0.2
  web:
    http_port: 8001
  database:
    host: postgres
    port: "5432"
    password: LAB_ONLY_NETBOX_POSTGRES_PASSWORD_DO_NOT_REUSE
    network:
      name: tmnt_postgres
      external: true
  redis:
    password: change-me-redis
    cache_password: change-me-redis-cache
  security:
    secret_key: change-me-change-me-change-me-change-me-change-me-change-me
  superuser:
    enabled: true
    name: admin
    email: admin@example.invalid
    password: change-me-admin
```

NetBox Docker images should be upgraded deliberately. The default tag follows the current `netbox-docker` release branch compatibility pattern rather than an unpinned `latest`.

The role renders `/opt/docker/netbox/config/zz_tmnt_lab_compatibility.py` and mounts it read-only into `/etc/netbox/config/`. This removes the image-provided deprecated `LOGIN_REQUIRED` configuration attribute while preserving NetBox's authenticated-only default behavior for NetBox v4.6 and the future v5.0 upgrade path.

Deploy `docker_postgres` and `ops_postgres` before this role. For an existing installation, export `/opt/docker/netbox/postgres` and import it into the shared PostgreSQL service before switching the application; this refactor deliberately does not move or delete old database data.
