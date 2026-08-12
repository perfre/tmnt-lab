# docker_mariadb

Owns the shared MariaDB Compose runtime, the internal `tmnt_mariadb` application network, and the separate `tmnt_mariadb_admin` administrative network used for the published TCP listener. It does not create application databases or users; `ops_mariadb` owns that inventory-driven state.

This implementation is inventory-profiled but the database runtime is still limited to a loopback administrative listener because it does not yet configure MariaDB TLS. The cross-project application network remains internal. The committed local inventory supplies a conspicuously synthetic administrator credential; production work must add verified database TLS and a protected secret source before exposing administration beyond loopback.

The administrator secret is rendered at `/opt/docker/mariadb/root-password` as `root:999` mode `0640` because the MariaDB container runs as UID/GID `999:999` and Docker Compose bind-mounts file-backed secrets with host permissions. Do not add unrelated host users to group ID `999` in the lab.

Persistent data is stored at `/opt/docker/mariadb/data`. Back it up before an image upgrade. Consumers attach to `tmnt_mariadb` and resolve the service as `mariadb`.

```yaml
docker_mariadb:
  bind_address: 127.0.0.1
  listen_port: 3306
  admin_password: LAB_ONLY_MARIADB_ADMIN_PASSWORD_DO_NOT_REUSE
  network:
    name: tmnt_mariadb
    alias: mariadb
  admin_network:
    name: tmnt_mariadb_admin
    alias: mariadb-admin
```
