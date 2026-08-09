# docker_snmpv3_testhost

Runs one or more Linux `snmpd` containers for SNMPv3 polling tests.

All inventory/default configuration lives under `docker_snmpv3_testhost`.

```yaml
docker_snmpv3_testhost:
  default_user:
    name: poller
    auth_protocol: SHA
    auth_password: authpass123
    privacy_protocol: AES
    privacy_password: privpass123
    security_level: authPriv
  containers:
    snmpv3-linux01:
      host_port: 1161
      sysdescr: Linux SNMPv3 test host
    snmpv3-linux02:
      host_port: 1162
      user:
        name: poller2
```
