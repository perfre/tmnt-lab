# docker_netbox

Runs NetBox with PostgreSQL and Valkey using Docker Compose.

All inventory/default configuration lives under `docker_netbox`.

```yaml
docker_netbox:
  project_dir: /opt/docker/netbox
  image: docker.io/netboxcommunity/netbox:v4.6-5.0.2
  web:
    http_port: 8001
  database:
    password: change-me
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
