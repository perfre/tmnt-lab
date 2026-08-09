# docker_zabbix

Runs Zabbix 7.4 on Docker Compose with PostgreSQL. Defaults use the `alpine-7.4-latest` Zabbix image tag so a playbook run pulls the latest 7.4 patch release.

All inventory/default configuration lives under `docker_zabbix`.

```yaml
docker_zabbix:
  project_dir: /opt/docker/zabbix
  timezone: Europe/Stockholm
  postgres:
    password: change-me
  web:
    http_port: 8080
  plugin_mounts:
    - source: /srv/zabbix/plugins/externalscripts
      target: /usr/lib/zabbix/externalscripts
      read_only: true
    - source: /srv/zabbix/plugins/modules
      target: /var/lib/zabbix/modules
      read_only: true
```
