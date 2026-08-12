# ops_openbao_ldap

Enables and configures the OpenBao LDAP auth method in an existing, initialized, and unsealed `docker_openbao` deployment. The role requires an operator token supplied from Vault, an external secret manager, or uncommitted inventory.

```yaml
ops_openbao_ldap:
  enabled: true
  token: "{{ vault_openbao_operator_token }}"
  ldap:
    url: ldaps://openldap:1636
    bind_dn: cn=openbao,ou=services,dc=tmnt,dc=localhost
    bind_password: LAB_ONLY_OPENBAO_LDAP_BIND_PASSWORD_DO_NOT_REUSE
    user_dn: ou=people,dc=tmnt,dc=localhost
    group_dn: ou=groups,dc=tmnt,dc=localhost
```

The role rejects `insecure_tls` and expects the OpenLDAP CA to be mounted into the OpenBao container by `docker_openbao`. It does not initialize, unseal, create policies, or generate tokens. Roll back by disabling or deleting the configured auth mount with a deliberate OpenBao operation.
