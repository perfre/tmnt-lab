# docker_openbao

Runs OpenBao with Docker Compose using the official OpenBao container image.

All inventory/default configuration lives under `docker_openbao`.

```yaml
docker_openbao:
  project_dir: /opt/docker/openbao
  image: ghcr.io/openbao/openbao:latest
  ports:
    - 8200:8200
  ldap:
    enabled: true
    ca_path: /opt/docker/openldap/pki/ca.crt
  config:
    ui: true
    disable_mlock: true
    listener:
      address: 0.0.0.0:8200
      tls_disable: true
    storage:
      file:
        path: /bao/file
```

When `ldap.enabled` is true, the OpenBao container joins the external LDAP network and mounts the OpenLDAP CA read-only for the LDAP auth method. The auth method itself is configured by `ops_openbao_ldap`, which requires an initialized and unsealed OpenBao plus an operator token. This role does not initialize, unseal, or mint tokens.
