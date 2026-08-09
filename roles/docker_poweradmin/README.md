# docker_poweradmin

Runs the official Poweradmin container behind an Nginx TLS proxy. This role is localhost-lab only: it refuses remote targets, binds HTTPS to `127.0.0.1`, uses synthetic credentials, creates a disposable local CA, and connects to PowerDNS through the internal API network owned by `docker_powerdns`.

## Requirements

- Docker Engine with the Compose v2 plugin
- `community.docker` and `community.crypto`
- `docker_mariadb` and `ops_mariadb` deployed first
- `docker_powerdns` deployed first so `tmnt_powerdns_api` exists

## Configuration

All variables live under `docker_poweradmin`.

```yaml
docker_poweradmin:
  lab_mode: true
  bind_address: 127.0.0.1
  web:
    hostname: poweradmin.localhost
    https_port: 8445
  database:
    name: powerdns
    user: poweradmin
    password: LAB_ONLY_POWERADMIN_MARIADB_PASSWORD_DO_NOT_REUSE
    init_pdns_schema: true
  powerdns_api:
    url: http://powerdns:8081
    key: LAB_ONLY_POWERDNS_API_KEY_DO_NOT_REUSE
```

Poweradmin initializes its own tables and the PowerDNS schema in the shared `powerdns` lab database on first startup. The database is intentionally shared in this disposable lab because the current repository has no production schema-migration role for PowerDNS yet.

## Ports, Data, And Trust

- Lab UI: `https://poweradmin.localhost:8445`
- Runtime files: `/opt/docker/poweradmin`
- Disposable public CA: `/opt/docker/poweradmin/pki/ca.crt`
- Persistent application state: shared MariaDB database `powerdns`

Secrets are written below `/opt/docker/poweradmin/secrets` as `root:82` mode `0640` so the non-root container can read file-backed Compose secrets through `*_FILE` environment variables. The PowerDNS API connection is plaintext but stays on the internal `tmnt_powerdns_api` network and requires the synthetic API key.

The Nginx proxy allows TLS 1.2 and 1.3. Import only the generated public CA into browsers or clients used for this lab; never trust or reuse it outside localhost.

## Deploy

```bash
ansible-playbook -i inventory-local/hosts.yml services.yml \
  --tags docker_mariadb,ops_mariadb,docker_powerdns,docker_poweradmin
```

Open:

- `https://poweradmin.localhost:8445`

The initial lab administrator is `admin` with the synthetic password from inventory. Replace it inside the lab UI if you keep the disposable environment for more than a quick test.

## Verification

```bash
sudo docker compose -f /opt/docker/poweradmin/compose.yml config --quiet
sudo systemctl status docker-poweradmin
openssl s_client -verify_return_error \
  -CAfile /opt/docker/poweradmin/pki/ca.crt \
  -connect poweradmin.localhost:8445 -servername poweradmin.localhost </dev/null
ss -lntup | grep 8445
```

## Reset Or Remove

This removes Poweradmin containers, local TLS material, and rendered secrets. It does not remove the shared MariaDB database:

```bash
sudo systemctl disable --now docker-poweradmin
sudo docker compose -f /opt/docker/poweradmin/compose.yml down --remove-orphans
sudo rm -rf /opt/docker/poweradmin
```

Confirm backups before dropping the `powerdns` MariaDB database, because that also removes PowerDNS zone data.
