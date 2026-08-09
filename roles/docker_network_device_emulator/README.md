# docker_network_device_emulator

Runs SNMPSim containers that emulate network devices for monitoring pollers. The role builds a small local image from `python:3.12-alpine` and installs `snmpsim` from PyPI.

SNMPSim is used here because it replays SNMP footprints from `.snmprec` data, which is the most useful container approach for pretending to poll HP, Huawei, Cisco, ZTE and similar devices. For real routing protocol labs, use containerlab with vendor NOS images instead.

All inventory/default configuration lives under `docker_network_device_emulator`.

```yaml
docker_network_device_emulator:
  network:
    name: zabbix_zabbix
    external: true
  devices:
    cisco-ios01:
      host_port: 2161
      community: cisco
      sysdescr: Cisco IOS Software mock
      sysobjectid: 1.3.6.1.4.1.9.1.1208
      interfaces:
        - index: 1
          descr: GigabitEthernet0/1
          oper_status: 1
```

When Zabbix runs in the `docker_zabbix` Compose project, keep the default external network `zabbix_zabbix` and add hosts by DNS name from inside Docker, for example `cisco-ios01` on port `161` with `{$SNMP_COMMUNITY}=cisco`.

If the emulator runs outside the Zabbix Docker network, add hosts by Docker host IP and the published UDP ports instead, for example port `2161` for `cisco-ios01`.
