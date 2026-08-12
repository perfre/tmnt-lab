# ops_openldap

Reconciles inventory-defined OpenLDAP directory content on a running LDAP server. The role creates the base entry, organizational units, extra entries, users, and groups using `community.general.ldap_entry` and `community.general.ldap_attrs`.

The role does not delete unlisted entries. Set `state: absent` explicitly for deliberate removals.

## Variables

```yaml
ops_openldap:
  server_uri: ldaps://127.0.0.1:1636
  validate_certs: true
  ca_path: /opt/docker/openldap/pki/ca.crt
  bind_dn: cn=admin,dc=example,dc=org
  bind_password: LAB_ONLY_OPENLDAP_ADMIN_PASSWORD_DO_NOT_REUSE
  base_dn: dc=example,dc=org
  base:
    object_classes: [top, dcObject, organization]
    attributes:
      dc: example
      o: Example Directory
  users:
    - uid: alice
      attributes:
        uid: alice
        cn: Alice Example
        sn: Example
        uidNumber: "10000"
        gidNumber: "10000"
        homeDirectory: /home/alice
        loginShell: /bin/bash
      password: LAB_ONLY_ALICE_LDAP_PASSWORD_DO_NOT_REUSE
      password_hash_salt: aliceSalt1
  groups:
    - cn: admins
      attributes:
        cn: admins
        member:
          - uid=alice,ou=people,dc=example,dc=org
```

Users and groups accept either a full `dn` or a default `uid=<uid>,<users_ou_dn>` / `cn=<cn>,<groups_ou_dn>` DN. Users and `extra_entries` can set passwords as `password_hash`, or as `password` plus a deterministic `password_hash_salt`. The committed lab inventory uses `extra_entries` under `ou=services` for least-privilege application bind accounts. Secret-bearing tasks are redacted.

## Security

Verified LDAPS or StartTLS is required by default. Plain LDAP requires `allow_plaintext: true` in inventory, which should be limited to isolated test fixtures. The role installs the target host's `python3-ldap` package so Ansible can use the LDAP modules.

Groups using `groupOfNames` must declare at least one `member` because the schema requires it and memberOf updates need real DN-valued membership.

## Deployment

Run this after `docker_openldap` or another reachable OpenLDAP deployment is healthy:

```bash
/usr/local/bin/deploy services.yml \
  --tags ops_openldap --limit ldap
```

Verify memberOf:

```bash
LDAPTLS_CACERT=/opt/docker/openldap/pki/ca.crt \
ldapsearch -H ldaps://127.0.0.1:1636 \
  -x -D cn=admin,dc=example,dc=org -W \
  -b uid=alice,ou=people,dc=example,dc=org memberOf
```

## Rollback

Rollback is object-level. Reapply a previous inventory state or mark entries `state: absent` for intentional removals. For large changes, back up the OpenLDAP data directory before reconciling.
