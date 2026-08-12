# ops_zabbix_ldap

Reconciles a Zabbix LDAP user directory and enables LDAP authentication through the `community.zabbix` API modules. Run it after `docker_zabbix` is reachable and the frontend has LDAP network access plus any required CA bundle.

```yaml
ops_zabbix_ldap:
  enabled: true
  api:
    host: 127.0.0.1
    port: 8080
    allow_plaintext: true
    username: Admin
    password: LAB_ONLY_ZABBIX_API_PASSWORD_DO_NOT_REUSE
  user_directory:
    host: ldaps://openldap
    port: 1636
    bind_dn: cn=zabbix,ou=services,dc=tmnt,dc=localhost
    bind_password: LAB_ONLY_ZABBIX_LDAP_BIND_PASSWORD_DO_NOT_REUSE
```

The API endpoint may use loopback HTTP only in disposable lab inventories. Production use requires HTTPS with certificate validation and an API token or protected administrator credential. The role does not rotate Zabbix's built-in `Admin` password.
