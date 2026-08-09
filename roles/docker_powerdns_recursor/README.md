# docker_powerdns_recursor

Runs a PowerDNS Recursor container for disposable localhost DNS resolution tests. The role refuses remote targets and binds the resolver to a loopback-only, unprivileged DNS port.

## Requirements

- Docker Engine with the Compose v2 plugin
- `community.docker`
- `docker_powerdns` first when `authoritative_network.enabled` is true

## Configuration

All variables live under `docker_powerdns_recursor`.

```yaml
docker_powerdns_recursor:
  lab_mode: true
  bind_address: 127.0.0.1
  dns:
    published_port: 5301
  dnssec:
    validation: validate
  forward_zones:
    - zone: lab.example
      target: powerdns-auth:5300
```

`forward_zones` is optional. When used, the recursor joins the `tmnt_powerdns_dns` network owned by `docker_powerdns` and can forward selected lab zones to the authoritative service.

## Ports, Data, and Trust

- Lab resolver endpoint: `127.0.0.1:5301` over TCP and UDP
- Runtime files: `/opt/docker/powerdns-recursor`
- Persistent data: none

This is a plaintext DNS lab endpoint bound to loopback. Production use is blocked until exposure, client trust, DNS encryption strategy, and secret handling are designed for the target network.

## Deploy

```bash
ansible-playbook -i inventory-local/hosts.yml services.yml \
  --tags docker_powerdns,docker_powerdns_recursor
```

## Verification

```bash
sudo docker compose -f /opt/docker/powerdns-recursor/compose.yml config --quiet
sudo systemctl status docker-powerdns-recursor
dig @127.0.0.1 -p 5301 example.com A
ss -lntup | grep 5301
```

## Reset Or Remove

```bash
sudo systemctl disable --now docker-powerdns-recursor
sudo docker compose -f /opt/docker/powerdns-recursor/compose.yml down --remove-orphans
sudo rm -rf /opt/docker/powerdns-recursor
```
