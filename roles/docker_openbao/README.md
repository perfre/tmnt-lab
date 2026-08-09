# docker_openbao

Runs OpenBao with Docker Compose using the official OpenBao container image.

All inventory/default configuration lives under `docker_openbao`.

```yaml
docker_openbao:
  project_dir: /opt/docker/openbao
  image: ghcr.io/openbao/openbao:latest
  ports:
    - 8200:8200
  config:
    ui: true
    disable_mlock: true
    listener:
      address: 0.0.0.0:8200
      tls_disable: true
    storage:
      file:
        path: /bao/file
```
