# docker_postgres

Owns the shared PostgreSQL Compose runtime, the internal `tmnt_postgres` application network, and the separate `tmnt_postgres_admin` administrative network used for the published TCP listener. It does not create application databases or users; `ops_postgres` owns that inventory-driven state.

This implementation is deliberately limited to the disposable localhost lab. Its administrative port is bound to `127.0.0.1` through the administrative network, the cross-project application network remains internal, and the committed credential is conspicuously synthetic. Do not reuse it. A production extension must add verified database TLS and an external secret source before relaxing the lab assertions or exposing the admin listener beyond loopback.

The synthetic administrator secret is rendered at `/opt/docker/postgres/postgres-password` as `root:999` mode `0640` because the PostgreSQL container runs as UID/GID `999:999` and Docker Compose bind-mounts file-backed secrets with host permissions. Do not add unrelated host users to group ID `999` in the lab.

Persistent data is stored at `/opt/docker/postgres/data`. Back it up before an image upgrade. Consumers attach to `tmnt_postgres` and resolve the service as `postgres`.

```yaml
docker_postgres:
  lab_mode: true
  bind_address: 127.0.0.1
  listen_port: 5432
  network:
    name: tmnt_postgres
    alias: postgres
  admin_network:
    name: tmnt_postgres_admin
    alias: postgres-admin
```
