# docker_netbox

Runs NetBox with Valkey using Docker Compose. PostgreSQL is an external dependency owned by `docker_postgres`; its database and application user are owned by `ops_postgres`.

All inventory/default configuration lives under `docker_netbox`.

```yaml
docker_netbox:
  project_dir: /opt/docker/netbox
  image: docker.io/netboxcommunity/netbox:v4.6-5.0.2
  allowed_hosts:
    - netbox.example.invalid
  web:
    http_port: 8001
  database:
    host: postgres
    port: "5432"
    password: LAB_ONLY_NETBOX_POSTGRES_PASSWORD_DO_NOT_REUSE
    network:
      name: tmnt_postgres
      external: true
  redis:
    password: LAB_ONLY_NETBOX_REDIS_PASSWORD_DO_NOT_REUSE
    cache_password: LAB_ONLY_NETBOX_REDIS_CACHE_PASSWORD_DO_NOT_REUSE
  security:
    secret_key: LAB_ONLY_NETBOX_SECRET_KEY_0123456789_DO_NOT_REUSE_0123456789
    api_token_pepper_1: LAB_ONLY_NETBOX_API_TOKEN_PEPPER_DO_NOT_REUSE_0123456789
  superuser:
    enabled: true
    name: admin
    email: admin@example.invalid
    password: LAB_ONLY_NETBOX_ADMIN_PASSWORD_DO_NOT_REUSE
  ldap:
    enabled: true
    server_uri: ldaps://openldap:1636
    ca_path: /opt/docker/openldap/pki/ca.crt
    bind_dn: cn=netbox,ou=services,dc=tmnt,dc=localhost
    bind_password: LAB_ONLY_NETBOX_LDAP_BIND_PASSWORD_DO_NOT_REUSE
```

NetBox Docker images should be upgraded deliberately. The default tag follows the current `netbox-docker` release branch compatibility pattern rather than an unpinned `latest`.

The role renders `/opt/docker/netbox/config/zz_tmnt_lab_compatibility.py` and mounts it read-only into `/etc/netbox/config/`. This removes the image-provided deprecated `LOGIN_REQUIRED` configuration attribute while preserving NetBox's authenticated-only default behavior for NetBox v4.6 and the future v5.0 upgrade path.

When `ldap.enabled` is true, the role sets NetBox's LDAP remote-auth environment variables, mounts the OpenLDAP CA read-only, and joins the external LDAP network. LDAP must use verified LDAPS or StartTLS unless inventory explicitly opts into plaintext for an isolated fixture. Use a least-privilege bind account and map admin/superuser privileges through LDAP group DNs.

Deploy `docker_postgres` and `ops_postgres` before this role. For an existing installation, export `/opt/docker/netbox/postgres` and import it into the shared PostgreSQL service before switching the application; this refactor deliberately does not move or delete old database data.
