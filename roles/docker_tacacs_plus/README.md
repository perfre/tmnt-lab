# docker_tacacs_plus

Builds and runs `tac_plus-ng` from a pinned upstream commit on a Debian base image. The role supports native LDAP integration through the upstream MAVIS LDAP helper and keeps the container unprivileged by listening on TCP `4949` by default.

```yaml
docker_tacacs_plus:
  bind_address: 127.0.0.1
  published_port: 4949
  clients:
    - name: local_lab
      address: 0.0.0.0/0
      key: LAB_ONLY_TACACS_SHARED_KEY_DO_NOT_REUSE
  ldap:
    enabled: true
    server_uri: ldaps://openldap:1636
    ca_path: /opt/docker/openldap/pki/ca.crt
    bind_dn: cn=tacacs,ou=services,dc=tmnt,dc=localhost
    bind_password: LAB_ONLY_TACACS_LDAP_BIND_PASSWORD_DO_NOT_REUSE
    admin_group_cn: tacacs-admins
```

LDAP must use verified LDAPS or StartTLS unless inventory explicitly opts into plaintext for an isolated test fixture. Group membership maps `tacacs-admins` to privilege level 15 and `tacacs-readonly` to privilege level 1 by default.

Deploy with:

```bash
/usr/local/bin/deploy services.yml --tags docker_tacacs_plus --limit tacacs
```

Verify with `docker compose -f /opt/docker/tacacs-plus/compose.yml config --quiet`, `systemctl status docker-tacacs-plus`, and a TACACS+ test client using the configured shared key.
