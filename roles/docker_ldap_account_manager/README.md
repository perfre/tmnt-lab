# docker_ldap_account_manager

Runs LDAP Account Manager (LAM) as a Docker Compose project for managing an LDAP directory. The LAM application stays on an internal frontend network; the role publishes only an Nginx HTTPS proxy when `web.publish` is enabled.

LAM connects to LDAP with verified LDAPS. The role mounts the LDAP CA certificate into the container and renders `/etc/ldap/ldap.conf` so PHP LDAP clients validate the chain.

## Variables

```yaml
docker_ldap_account_manager:
  ldap:
    server_url: ldaps://openldap:1636
    base_dn: dc=example,dc=org
    users_dn: ou=people,dc=example,dc=org
    groups_dn: ou=groups,dc=example,dc=org
    bind_dn: cn=admin,dc=example,dc=org
    ca_path: /opt/docker/openldap/pki/ca.crt
    network:
      name: tmnt_openldap
      external: true
  configuration:
    preconfigure: true
    password: LAB_ONLY_OPENLDAP_ADMIN_PASSWORD_DO_NOT_REUSE
  web:
    publish: true
    bind_address: 127.0.0.1
    hostname: lam.localhost
    https_port: 8446
```

`configuration.password` is passed through `LAM_PASSWORD_FILE`. Upstream LAM uses it as the configuration master password and as the password for the preconfigured server profile. Use a dedicated LDAP bind account instead of the directory root DN when your inventory has one.

If all web TLS paths are empty, the role generates a local CA and leaf certificate under `web.tls.pki_dir`. If any path is set, all three paths (`ca_path`, `cert_path`, `key_path`) must be set.

## Ports And Data

- LAM config: `/opt/docker/ldap-account-manager/config`
- LAM main config: `/opt/docker/ldap-account-manager/main-config`
- LAM web PKI: `/opt/docker/ldap-account-manager/pki`
- Published HTTPS: inventory-defined, default container/host port `8446`

## Security

The LAM image is digest-pinned and runs as `www-data` (`33:33`). The application container drops all Linux capabilities, uses `no-new-privileges`, and has a read-only root filesystem with explicit writable config volumes and tmpfs paths. The Nginx proxy allows TLS 1.2 and TLS 1.3.

## Deployment

Run after OpenLDAP is reachable and the LDAP network exists:

```bash
/usr/local/bin/deploy services.yml \
  --tags docker_ldap_account_manager --limit ldap
```

Validate the rendered Compose model and HTTPS endpoint:

```bash
docker compose -f /opt/docker/ldap-account-manager/compose.yml config --quiet
openssl s_client -verify_return_error \
  -CAfile /opt/docker/ldap-account-manager/pki/ca.crt \
  -connect 127.0.0.1:8446 \
  -servername lam.localhost
```

## Upgrade And Rollback

Change the digest-pinned `image` after reviewing the LAM release notes and validating compatibility. Back up the two LAM config directories before upgrades. Roll back by restoring the previous config backup and image reference, then restart `docker-ldap-account-manager`.
