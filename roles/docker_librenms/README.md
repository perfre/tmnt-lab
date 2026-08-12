# docker_librenms

Runs LibreNMS with Redis, dispatcher, syslog-ng, and snmptrapd sidecars using Docker Compose. MariaDB is an external dependency owned by `docker_mariadb`; its database and application user are owned by `ops_mariadb`.

All inventory/default configuration lives under `docker_librenms`.

```yaml
docker_librenms:
  project_dir: /opt/docker/librenms
  database:
    host: mariadb
    port: "3306"
    password: LAB_ONLY_LIBRENMS_MARIADB_PASSWORD_DO_NOT_REUSE
    network:
      name: tmnt_mariadb
      external: true
  web:
    http_port: 8000
  services:
    dispatcher: true
    syslogng: true
    snmptrapd: true
    msmtpd: true
  ldap:
    enabled: true
    ca_path: /opt/docker/openldap/pki/ca.crt
```

When `ldap.enabled` is true, the runtime joins the external LDAP network and mounts the OpenLDAP CA bundle for LibreNMS. Application authentication settings are reconciled separately by `ops_librenms_ldap` through the `lnms` CLI so runtime and application state remain distinct.

Deploy `docker_mariadb` and `ops_mariadb` before this role. Deploy `docker_openldap` and `ops_openldap` before enabling LDAP. For an existing installation, export `/opt/docker/librenms/db` and import it into the shared MariaDB service before switching the application; this refactor deliberately does not move or delete old database data.
