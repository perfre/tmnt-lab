# docker_openldap

Builds and runs a Debian-based OpenLDAP Compose project. The role owns only the `slapd` runtime, image build context, TLS material used by the container, data directory, Compose file, and systemd unit. Directory content is provisioned separately by `ops_openldap`.

OpenLDAP runs with `slapd.conf`, MDB storage, native LDAPS/StartTLS, and the `memberof` plus `refint` overlays. The container listens on unprivileged ports by default (`1389` LDAP and `1636` LDAPS); inventory decides whether either port is published and which host address/port is used.

## Variables

```yaml
docker_openldap:
  suffix: dc=example,dc=org
  organization: Example Directory
  admin:
    dn: cn=admin,dc=example,dc=org
    password_hash: "{SSHA}..."
    password: ""
    password_hash_salt: ""
  tls:
    ca_path: /etc/pki/openldap/ca.crt
    cert_path: /etc/pki/openldap/server.crt
    key_path: /etc/pki/openldap/server.key
  ldaps:
    publish: true
    bind_address: 192.0.2.10
    published_port: 636
```

Provide either `admin.password_hash` or `admin.password` with `admin.password_hash_salt`. Production inventories should prefer a precomputed OpenLDAP hash from Vault, an uncommitted inventory, or another approved secret source. Committed examples must use only synthetic values.

If all TLS host paths are empty, the role generates a local CA and a leaf certificate under `pki_dir`. If any TLS host path is set, all three paths (`ca_path`, `cert_path`, `key_path`) must be set and are mounted read-only. Generated leaf certificates default to 397 days and renew before expiry.

## Ports And Data

- Data: `/opt/docker/openldap/data`
- Rendered config: `/opt/docker/openldap/config/slapd.conf`
- Generated local PKI: `/opt/docker/openldap/pki`
- Internal network: `tmnt_openldap`
- Container LDAP: `1389/tcp`
- Container LDAPS: `1636/tcp`

Published ports are disabled by default. Set `ldap.publish` or `ldaps.publish` in inventory when host access is required.

## Trust Model

OpenLDAP terminates TLS directly. Health checks use LDAPS with CA validation. The container runs directly as Debian's `openldap` user (`100:101`), drops all Linux capabilities, uses `no-new-privileges`, and has a read-only root filesystem. Ansible prepares the writable data and runtime directories with the required ownership before Compose starts the service.

The generated CA is local deployment material. For production, either replace it with inventory-provided certificate paths from your PKI or treat the generated CA as target-local trust material and distribute only its public certificate deliberately.

## Deployment

```bash
/usr/local/bin/deploy services.yml \
  --tags docker_openldap --limit ldap
```

Validate the rendered Compose model:

```bash
docker compose -f /opt/docker/openldap/compose.yml config --quiet
openssl s_client -verify_return_error \
  -CAfile /opt/docker/openldap/pki/ca.crt \
  -connect 127.0.0.1:1636 \
  -servername localhost
```

## Upgrade And Rollback

Change `base_image` or the OpenLDAP image build inputs in inventory or defaults, validate the rendered Compose model, and deploy `docker_openldap` before running `ops_openldap`. Back up `/opt/docker/openldap/data`, `/opt/docker/openldap/config`, and any generated PKI before image or schema changes.

Rollback by restoring the previous Compose/config/PKI backup and restarting `docker-openldap`. Do not delete the data directory unless you have verified backups and intend to rebuild the directory.
