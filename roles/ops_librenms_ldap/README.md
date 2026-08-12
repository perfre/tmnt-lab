# ops_librenms_ldap

Configures LibreNMS LDAP authentication settings inside an existing `docker_librenms` Compose project by running the `lnms config:set` CLI. The runtime role must already have LDAP network access and any required CA bundle mounted.

```yaml
ops_librenms_ldap:
  enabled: true
  server_uri: ldaps://openldap:1636
  bind_dn: cn=librenms,ou=services,dc=tmnt,dc=localhost
  bind_password: LAB_ONLY_LIBRENMS_LDAP_BIND_PASSWORD_DO_NOT_REUSE
  base_dn: ou=people,dc=tmnt,dc=localhost
  group_base_dn: ou=groups,dc=tmnt,dc=localhost
  admin_group_cn: librenms-admins
```

Verified LDAPS is required unless inventory explicitly sets `allow_plaintext: true`. Real bind credentials belong in Vault, an external secret manager, or an uncommitted inventory. Roll back by setting `enabled: false`, which restores `auth_mechanism` to `mysql`.
