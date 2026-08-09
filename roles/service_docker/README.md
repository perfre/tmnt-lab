# service_docker

Installs the official Docker repository and the latest Docker CE packages with conservative daemon defaults.

All inventory/default configuration lives under `service_docker`.

```yaml
service_docker:
  state: latest
  channel: stable
  users:
    - crypt
  daemon:
    log-driver: json-file
    log-opts:
      max-size: 10m
      max-file: "3"
    storage-driver: overlay2
    live-restore: true
```
