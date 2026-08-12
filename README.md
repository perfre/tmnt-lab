# tmnt-lab

`tmnt-lab` is an Ansible-managed collection of Docker Compose services for disposable lab profiles and production-capable inventory profiles. Ansible owns host preparation, rendered Compose projects, systemd lifecycle, persistent paths, and operational bootstrap tasks. Do not operate parallel hand-written Compose deployments for the same services.

The repository is inventory-driven. The committed local inventory is only one localhost profile with synthetic values; production behavior is selected through separate inventory variables for secrets, PKI, bind addresses, networks, and published ports. Some older roles still have production security debt, and the production section identifies those gaps.

## Repository map

- `services.yml`: single deployment entry point for lab and production inventories.
- `inventory-local/hosts.yml`: disposable localhost/WSL lab inventory with synthetic credentials.
- `inventory-production.example/hosts.yml`: safe starting point for the currently supported Docker/Ollama production boundary.
- `roles/service_*`: host packages and daemons, such as Docker Engine and NVIDIA CDI.
- `roles/docker_*`: one Docker Compose runtime per role.
- `roles/ops_*`: operational state such as database schemas, users, and Ollama models.
- `AGENTS.md`: contributor and automation rules, security baseline, and architectural decisions.

Runtime roles execute before their matching operations roles. For example:

```text
service_docker
  -> docker_ollama_server
     -> ops_ollama_models
  -> docker_openldap
     -> ops_openldap
     -> docker_ldap_account_manager
```

## Prerequisites

- A recent Debian/Ubuntu or RedHat-family system with systemd.
- Python 3, sudo access, and enough disk space under `/opt/docker`.
- Docker-compatible CPU and memory resources for the selected services.
- For NVIDIA acceleration, a physical-host NVIDIA driver. On WSL2, install the NVIDIA driver in Windows only; do not install a Linux display driver inside WSL.
- For the default Ollama models, approximately 10 GB free disk space and a 12 GiB GPU are recommended.

Install the repository's Ansible environment and collections:

```bash
sudo ./ansible-setup.sh
```

Alternatively, use an existing Ansible installation and install collections directly:

```bash
ansible-galaxy collection install -r ansible-galaxy-requirements.yml
```

Validate before deployment:

```bash
ansible-inventory -i inventory-local/hosts.yml --graph
ansible-playbook -i inventory-local/hosts.yml services.yml --syntax-check
```

## Deploy the localhost lab

The local inventory uses `ansible_connection: local`. It stores only conspicuously synthetic application credentials and may prompt for the local sudo password with `-K`.

Deploy Docker, NVIDIA CDI, Ollama, and the default models:

```bash
ansible-playbook -K -i inventory-local/hosts.yml services.yml \
  --tags service_docker,docker_ollama_server,ops_ollama_models
```

The defaults pull and keep these models loaded concurrently:

- `qwen3:8b`: Apache-2.0 LLM, approximately 5.2 GB.
- `bge-m3:latest`: MIT multilingual embedding model, approximately 1.2 GB.

The lab uses a 4K context, one parallel request per model, Flash Attention, and a Q8 KV cache so both models fit on the 12 GiB WSL GPU.

Verify Ollama and GPU placement:

```bash
nvidia-ctk cdi list
curl --fail http://127.0.0.1:11434/api/version
docker exec ollama_server ollama list
docker exec ollama_server ollama ps
```

Test the LLM:

```bash
curl http://127.0.0.1:11434/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3:8b","messages":[{"role":"user","content":"Respond with one short sentence."}],"stream":false}'
```

Test embeddings:

```bash
curl http://127.0.0.1:11434/api/embed \
  -H 'Content-Type: application/json' \
  -d '{"model":"bge-m3:latest","input":"tmnt-lab embedding test"}'
```

Deploy the complete lab:

```bash
ansible-playbook -K -i inventory-local/hosts.yml services.yml
```

Before a complete deployment, read the MariaDB, PostgreSQL, LibreNMS, NetBox, Zabbix, Atlassian, PowerDNS, and Poweradmin role READMEs. The database refactor does not migrate data from older embedded database directories; application reconciliation can stop those old containers as orphans.
Also read the OpenLDAP, OpenLDAP operations, and LDAP Account Manager READMEs before deploying the LDAP stack because those roles create directory data, TLS material, and management UI state.

Deploy or check one component with tags and a limit:

```bash
ansible-playbook -K -i inventory-local/hosts.yml services.yml \
  --tags docker_netbox --limit netbox
ansible-playbook -K -i inventory-local/hosts.yml services.yml \
  --tags docker_openldap,ops_openldap,docker_ldap_account_manager --limit ldap
ansible-playbook -K -i inventory-local/hosts.yml services.yml \
  --check --diff --tags docker_ollama_server --limit ollama_server
```

Selecting only an application tag assumes its host and operational prerequisites have already run.

## Lab endpoints and data

| Service | Lab endpoint | Persistent path |
| --- | --- | --- |
| Ollama | `http://127.0.0.1:11434` | `/opt/docker/ollama-server/models` |
| Jira | `https://jira.localhost:8443` | `/opt/docker/atlassian-lab/jira` |
| Confluence | `https://confluence.localhost:8444` | `/opt/docker/atlassian-lab/confluence` |
| LibreNMS | `http://localhost:8000` | `/opt/docker/librenms` |
| NetBox | `http://localhost:8001` | `/opt/docker/netbox` |
| PowerDNS authoritative | `127.0.0.1:5300` TCP/UDP | MariaDB database `powerdns` |
| PowerDNS Recursor | `127.0.0.1:5301` TCP/UDP | `/opt/docker/powerdns-recursor` |
| Poweradmin | `https://poweradmin.localhost:8445` | MariaDB database `powerdns` |
| OpenLDAP LDAPS | `ldaps://127.0.0.1:1636` | `/opt/docker/openldap/data` |
| LDAP Account Manager | `https://lam.localhost:8446` | `/opt/docker/ldap-account-manager` |
| Zabbix | `http://localhost:8080` | `/opt/docker/zabbix` |
| MariaDB | loopback administration only | `/opt/docker/mariadb/data` |
| PostgreSQL | loopback administration only | `/opt/docker/postgres/data` |

MariaDB and PostgreSQL keep application traffic on internal Docker networks (`tmnt_mariadb`, `tmnt_postgres`) and publish loopback-only administrative listeners through separate admin networks (`tmnt_mariadb_admin`, `tmnt_postgres_admin`) for their matching `ops_*` roles.

PowerDNS authoritative owns the internal `tmnt_powerdns_api` network for Poweradmin API access and the internal `tmnt_powerdns_dns` network for optional recursor zone forwarding. Poweradmin initializes its own tables and the PowerDNS schema in the shared `powerdns` MariaDB database on first startup. The local inventory explicitly publishes the Poweradmin Nginx GUI through the proxy-only `poweradmin_ingress` bridge on `127.0.0.1:8445` as `https://poweradmin.localhost:8445`.

OpenLDAP publishes only LDAPS on loopback in the local inventory, generates local TLS when certificate paths are not supplied, and provisions users/groups through `ops_openldap` over CA-validated LDAPS. LDAP Account Manager connects to OpenLDAP over the internal `tmnt_openldap` network and publishes only its HTTPS proxy on `127.0.0.1:8446` in the local inventory.

Treat plaintext or broadly bound endpoints in older roles as known remediation debt; do not expose this WSL environment to an untrusted network.

## Production deployment

Use the same `services.yml` with a separate inventory. Never copy the synthetic local inventory into production.

Start from the safe example:

```bash
cp -R inventory-production.example inventory-production
```

Then:

1. Replace the example hostname and automation user.
2. Provide real secrets through Ansible Vault, an approved external secret manager, an uncommitted inventory, secure extra vars, or another documented operator-controlled source.
3. Provide production PKI certificate paths or intentionally generate target-local CA material and distribute only public CA certificates to clients that should trust it.
4. Set every published service bind address and port explicitly in inventory.
5. Keep unauthenticated service APIs unpublished unless a separately owned authenticated TLS ingress is configured.
6. Install the physical-host GPU driver outside Ansible when NVIDIA acceleration is used. The Docker role manages only NVIDIA Container Toolkit and CDI.

Validate and deploy a production inventory:

```bash
ansible-inventory -i inventory-production/hosts.yml --graph
ansible-playbook -i inventory-production/hosts.yml services.yml --syntax-check
ansible-playbook -K -i inventory-production/hosts.yml services.yml \
  --limit docker_hosts:ollama_server \
  --tags service_docker,docker_ollama_server,ops_ollama_models
```

Production status:

- `service_docker`: supports production Docker and optional NVIDIA CDI configuration.
- `docker_ollama_server`: safe production runtime contract only when its API remains unpublished behind a separately managed authenticated TLS ingress.
- `ops_ollama_models`: production-safe model pull/removal through container execution; API warm-up stays disabled until verified HTTPS ingress exists.
- `docker_openldap`: production-capable when inventory supplies real secret material, correct DN/SAN values, verified TLS trust, and deliberate publish/bind settings.
- `ops_openldap`: production-capable when inventory uses verified LDAPS or StartTLS and real bind credentials from a protected source.
- `docker_ldap_account_manager`: production-capable when inventory supplies verified LDAPS trust, a least-privilege LDAP bind account, and production web TLS or authenticated ingress.
- `docker_mariadb`, `docker_postgres`, `ops_mariadb`, `ops_postgres`, `docker_atlassian_lab`, `docker_powerdns`, `docker_powerdns_recursor`, and `docker_poweradmin`: currently localhost-lab only.
- LibreNMS, NetBox, Zabbix, OpenBao, and test-fixture roles still have production security debt. Do not treat them as production-ready without completing their TLS, secret, ingress, and image-pinning work.

There is not yet a repository-owned production PKI or authenticated ingress role. Use inventory-supplied certificate paths or a separately owned ingress where those controls are required; do not work around missing authentication by publishing unauthenticated APIs directly.

## Models, upgrades, and backups

Change the model list under `ops_ollama_models.models` in inventory. Every entry records its type, desired state, license, and upstream source. Unlisted models remain installed; use `state: absent` for deliberate removal.

Update models once:

```bash
ansible-playbook -K -i inventory-local/hosts.yml services.yml \
  --tags ops_ollama_models \
  -e '{"ops_ollama_models":{"update_present_models":true}}'
```

Return `update_present_models` to `false` after the refresh. For Ollama server upgrades, change both the pinned version tag and verified multi-platform digest in role defaults or inventory, validate the release, back up model data if required, and deploy the runtime before the operations role.

Back up persistent application directories under `/opt/docker` before database, directory, model, or image migrations. Stopping a Compose project does not remove bind-mounted data:

```bash
sudo systemctl stop docker-ollama-server
sudo tar -C /opt/docker -czf /path/to/ollama-server-backup.tgz ollama-server
sudo systemctl start docker-ollama-server
```

Choose a backup destination outside `/opt/docker` and protect it according to the data it contains.

For OpenLDAP, back up `/opt/docker/openldap/data`, `/opt/docker/openldap/config`, and any generated PKI before schema, image, or DN changes. For LDAP Account Manager, back up `/opt/docker/ldap-account-manager/config` and `/opt/docker/ldap-account-manager/main-config` before upgrades.

## Stop and remove runtime containers

Stop a service without deleting persistent data:

```bash
sudo systemctl disable --now docker-ollama-server
sudo docker compose -f /opt/docker/ollama-server/compose.yml down --remove-orphans
```

The roles do not automate destructive data deletion. Confirm exact paths and verified backups before manually removing anything below `/opt/docker`.

## Troubleshooting

- `nvidia-ctk cdi list` must include `nvidia.com/gpu=all`.
- `docker exec ollama_server ollama ps` reports whether each model is on GPU, CPU, or split.
- If both models cannot stay loaded, reduce context or parallelism before choosing smaller models.
- For OpenLDAP, verify LDAPS with `openssl s_client` and query memberOf with `ldapsearch` using the configured CA file.
- For LDAP Account Manager, inspect `systemctl status docker-ldap-account-manager` and the `lam`/`tls-proxy` container logs.
- Inspect `systemctl status docker-ollama-server` and `docker logs ollama_server` for startup failures.
- Run `docker compose ... config --quiet` against rendered Compose before restarting a service.
- Role-specific variables, trust boundaries, migrations, and reset procedures are documented in each `roles/<role>/README.md`.
