# docker_postgres

Owns the shared PostgreSQL Compose runtime and the internal `tmnt_postgres` Docker network. It does not create application databases or users; `ops_postgres` owns that inventory-driven state.

This implementation is deliberately limited to the disposable localhost lab. Its administrative port is bound to `127.0.0.1`, the cross-project network is internal, and the committed credential is conspicuously synthetic. Do not reuse it. A production extension must add verified database TLS and an external secret source before relaxing the lab assertions.

Persistent data is stored at `/opt/docker/postgres/data`. Back it up before an image upgrade. Consumers attach to `tmnt_postgres` and resolve the service as `postgres`.

```yaml
docker_postgres:
  lab_mode: true
  bind_address: 127.0.0.1
  listen_port: 5432
  network:
    name: tmnt_postgres
    alias: postgres
```
