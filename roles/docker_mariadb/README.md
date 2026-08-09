# docker_mariadb

Owns the shared MariaDB Compose runtime and the internal `tmnt_mariadb` Docker network. It does not create application databases or users; `ops_mariadb` owns that inventory-driven state.

This implementation is deliberately limited to the disposable localhost lab. Its administrative port is bound to `127.0.0.1`, the cross-project network is internal, and the committed credential is conspicuously synthetic. Do not reuse it. A production extension must add verified database TLS and an external secret source before relaxing the lab assertions.

Persistent data is stored at `/opt/docker/mariadb/data`. Back it up before an image upgrade. Consumers attach to `tmnt_mariadb` and resolve the service as `mariadb`.

```yaml
docker_mariadb:
  lab_mode: true
  bind_address: 127.0.0.1
  listen_port: 3306
  network:
    name: tmnt_mariadb
    alias: mariadb
```
