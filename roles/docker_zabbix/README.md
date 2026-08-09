# docker_zabbix

Runs Zabbix 7.4 on Docker Compose. PostgreSQL is an external dependency owned by `docker_postgres`; its database and application user are owned by `ops_postgres`. Defaults use the `alpine-7.4-latest` Zabbix image tag so a playbook run pulls the latest 7.4 patch release.

All inventory/default configuration lives under `docker_zabbix`.

```yaml
docker_zabbix:
  project_dir: /opt/docker/zabbix
  timezone: Europe/Stockholm
  database:
    host: postgres
    port: "5432"
    password: LAB_ONLY_ZABBIX_POSTGRES_PASSWORD_DO_NOT_REUSE
    network:
      name: tmnt_postgres
      external: true
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

Deploy `docker_postgres` and `ops_postgres` before this role. For an existing installation, export `/opt/docker/zabbix/postgres` and import it into the shared PostgreSQL service before switching the application; this refactor deliberately does not move or delete old database data.
