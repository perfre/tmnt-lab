# docker_librenms

Runs LibreNMS with MariaDB, Redis, dispatcher, syslog-ng and snmptrapd sidecars using Docker Compose.

All inventory/default configuration lives under `docker_librenms`.

```yaml
docker_librenms:
  project_dir: /opt/docker/librenms
  database:
    password: change-me
  web:
    http_port: 8000
  services:
    dispatcher: true
    syslogng: true
    snmptrapd: true
    msmtpd: true
```
