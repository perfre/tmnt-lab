# docker_freeradius

Builds and runs a Debian-based FreeRADIUS container with optional LDAP authentication. The role owns `/opt/docker/freeradius`, its Compose project, rendered RADIUS client config, and the systemd unit.

The default image disables the packaged EAP and inner-tunnel configuration because it references Debian's snakeoil private key. This role currently targets PAP-style RADIUS checks against local files or LDAP; certificate-backed EAP should be added with an explicit PKI variable contract before enabling it.

```yaml
docker_freeradius:
  bind_address: 127.0.0.1
  auth_port: 1812
  accounting_port: 1813
  clients:
    - name: local_lab
      ipaddr: 0.0.0.0/0
      secret: LAB_ONLY_RADIUS_SHARED_SECRET_DO_NOT_REUSE
  ldap:
    enabled: true
    server_uri: ldaps://openldap:1636
    ca_path: /opt/docker/openldap/pki/ca.crt
    bind_dn: cn=freeradius,ou=services,dc=tmnt,dc=localhost
    bind_password: LAB_ONLY_FREERADIUS_LDAP_BIND_PASSWORD_DO_NOT_REUSE
```

The LDAP backend uses verified LDAPS or StartTLS unless inventory explicitly sets `allow_plaintext: true`. PAP authentication can bind as the LDAP user; CHAP/MS-CHAP require password material that a normal LDAP directory should not expose and are not the default lab path.

Ports: UDP `1812` for authentication and UDP `1813` for accounting in the local inventory, both bound to loopback. Runtime files live under `/opt/docker/freeradius`; logs are in `/opt/docker/freeradius/log`.

Deploy with:

```bash
/usr/local/bin/deploy services.yml --tags docker_freeradius --limit radius
```

Verify with `docker compose -f /opt/docker/freeradius/compose.yml config --quiet`, `systemctl status docker-freeradius`, and a RADIUS client such as `radtest` using the configured shared secret.
