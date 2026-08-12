# docker_powerdns

Runs a PowerDNS Authoritative Server container with the Generic MySQL/MariaDB backend. The committed local inventory binds DNS to loopback, stores synthetic API credentials in a restricted config file, and keeps the HTTP API on an internal Docker network for `docker_poweradmin`. Inventory chooses the DNS bind address; keep synthetic `LAB_ONLY_*` credentials confined to local profiles.

## Requirements

- Docker Engine with the Compose v2 plugin
- `community.docker`
- `docker_mariadb` and `ops_mariadb` deployed first
- `docker_poweradmin` in the same deployment to initialize the shared lab database schema

## Configuration

All variables live under `docker_powerdns`.

```yaml
docker_powerdns:
  bind_address: 127.0.0.1
  dns:
    published_port: 5300
  database:
    host: mariadb
    name: powerdns
    user: powerdns
    password: LAB_ONLY_POWERDNS_MARIADB_PASSWORD_DO_NOT_REUSE
  api:
    key: LAB_ONLY_POWERDNS_API_KEY_DO_NOT_REUSE
    webserver_password: LAB_ONLY_POWERDNS_WEBSERVER_PASSWORD_DO_NOT_REUSE
```

The role owns the internal `tmnt_powerdns_api` network consumed by `docker_poweradmin` and the internal `tmnt_powerdns_dns` network consumed by `docker_powerdns_recursor`. Do not recreate or delete those networks from another role.

## Ports, Data, and Trust

- Lab DNS endpoint: `127.0.0.1:5300` over TCP and UDP
- Internal API: `http://powerdns:8081` on `tmnt_powerdns_api`
- Runtime files: `/opt/docker/powerdns`
- Persistent DNS state: shared MariaDB database `powerdns`

The PowerDNS HTTP API is plaintext because it is not published and is reachable only on the isolated Compose API network. Production use is blocked until the repository has a PKI-backed, authenticated DNS/API ingress, deliberate DNS exposure policy, and a protected secret source.

## Deploy

```bash
/usr/local/bin/deploy services.yml \
  --tags docker_mariadb,ops_mariadb,docker_powerdns,docker_poweradmin
```

`docker_poweradmin` initializes the shared database schema on first startup. On a completely fresh database, the authoritative container may restart until that schema exists.

## Verification

```bash
sudo docker compose -f /opt/docker/powerdns/compose.yml config --quiet
sudo systemctl status docker-powerdns
dig @127.0.0.1 -p 5300 SOA localhost
ss -lntup | grep 5300
```

## Reset Or Remove

This removes the containers and rendered config but not the shared MariaDB data:

```bash
sudo systemctl disable --now docker-powerdns
sudo docker compose -f /opt/docker/powerdns/compose.yml down --remove-orphans
sudo rm -rf /opt/docker/powerdns
```

Confirm backups before dropping the `powerdns` MariaDB database or deleting zones.
