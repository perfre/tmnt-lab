# docker_zabbix_testhost

Runs one or more Linux `zabbix_agent2` containers with mock UserParameter data for polling tests.

All inventory/default configuration lives under `docker_zabbix_testhost`. Containers are keyed by service/container name.

```yaml
docker_zabbix_testhost:
  server_host: zabbix-server
  network:
    name: zabbix_zabbix
    external: true
  containers:
    app-mock01:
      hostname: app-mock01
      host_metadata: linux app mock
      mock_values:
        cpu.load: "0.20"
        app.queue.depth: "12"
      random_ranges:
        cpu.random:
          min: 0
          max: 25
          format: "%.2f"
    db-mock01:
      hostname: db-mock01
      host_metadata: linux db mock
      host_port: 11050
      user_parameters:
        - key: db.connections
          command: echo 18
```
