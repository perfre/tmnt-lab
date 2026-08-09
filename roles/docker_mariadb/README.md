# docker_mariadb

Owns the shared MariaDB Compose runtime, the internal `tmnt_mariadb` application network, and the separate `tmnt_mariadb_admin` administrative network used for the published TCP listener. It does not create application databases or users; `ops_mariadb` owns that inventory-driven state.

This implementation is deliberately limited to the disposable localhost lab. Its administrative port is bound to `127.0.0.1` through the administrative network, the cross-project application network remains internal, and the committed credential is conspicuously synthetic. Do not reuse it. A production extension must add verified database TLS and an external secret source before relaxing the lab assertions or exposing the admin listener beyond loopback.

The synthetic administrator secret is rendered at `/opt/docker/mariadb/root-password` as `root:999` mode `0640` because the MariaDB container runs as UID/GID `999:999` and Docker Compose bind-mounts file-backed secrets with host permissions. Do not add unrelated host users to group ID `999` in the lab.

Persistent data is stored at `/opt/docker/mariadb/data`. Back it up before an image upgrade. Consumers attach to `tmnt_mariadb` and resolve the service as `mariadb`.

```yaml
docker_mariadb:
  lab_mode: true
  bind_address: 127.0.0.1
  listen_port: 3306
  network:
    name: tmnt_mariadb
    alias: mariadb
  admin_network:
    name: tmnt_mariadb_admin
    alias: mariadb-admin
```
