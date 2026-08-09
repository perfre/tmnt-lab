# tmnt-lab

`tmnt-lab` is an Ansible-managed collection of Docker Compose lab services. Ansible owns host preparation, rendered Compose projects, systemd lifecycle, persistent paths, and operational bootstrap tasks. Do not operate parallel hand-written Compose deployments for the same services.

The repository is lab-first. Some roles define a safe production contract, but the complete service collection is not yet production-ready. The production section below identifies the supported boundary and the controls that remain external.

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

Before a complete deployment, read the MariaDB, PostgreSQL, LibreNMS, NetBox, Zabbix, and Atlassian role READMEs. The database refactor does not migrate data from older embedded database directories; application reconciliation can stop those old containers as orphans.

Deploy or check one component with tags and a limit:

```bash
ansible-playbook -K -i inventory-local/hosts.yml services.yml \
  --tags docker_netbox --limit netbox
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
| Zabbix | `http://localhost:8080` | `/opt/docker/zabbix` |
| MariaDB | loopback administration only | `/opt/docker/mariadb/data` |
| PostgreSQL | loopback administration only | `/opt/docker/postgres/data` |

MariaDB keeps application traffic on the internal `tmnt_mariadb` Docker network and publishes the loopback-only administrative listener through a separate `tmnt_mariadb_admin` network for `ops_mariadb`.

Only the Ollama, Atlassian, and shared-database additions currently enforce the repository's strict localhost lab boundary. Treat other plaintext or broadly bound endpoints as known remediation debt; do not expose this WSL environment to an untrusted network.

## Production deployment

Use the same `services.yml` with a separate inventory. Never copy the synthetic local inventory into production.

Start from the safe example:

```bash
cp -R inventory-production.example inventory-production
```

Then:

1. Replace the example hostname and automation user.
2. Install the physical-host GPU driver outside Ansible. The Docker role manages only NVIDIA Container Toolkit and CDI.
3. Create the `secured_ai_ingress` network through a separately owned reverse-proxy deployment.
4. Configure that proxy with a local-PKI certificate, TLS 1.2 or newer, hostname verification, and strong client authentication.
5. Keep Ollama's port unpublished. The proxy joins `secured_ai_ingress` and forwards only authenticated HTTPS requests to `ollama:11434`.
6. Store any proxy credentials or private keys in Ansible Vault or an approved secret manager, never in plaintext inventory.

Validate and deploy the currently supported production boundary:

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
- `docker_mariadb`, `docker_postgres`, `ops_mariadb`, `ops_postgres`, and `docker_atlassian_lab`: currently localhost-lab only.
- LibreNMS, NetBox, Zabbix, OpenBao, and test-fixture roles still have production security debt. Do not treat them as production-ready without completing their TLS, secret, ingress, and image-pinning work.

There is not yet a repository-owned production PKI or authenticated ingress role. That missing control is intentional and blocks public production exposure; do not work around it by publishing Ollama directly.

## Models, upgrades, and backups

Change the model list under `ops_ollama_models.models` in inventory. Every entry records its type, desired state, license, and upstream source. Unlisted models remain installed; use `state: absent` for deliberate removal.

Update models once:

```bash
ansible-playbook -K -i inventory-local/hosts.yml services.yml \
  --tags ops_ollama_models \
  -e '{"ops_ollama_models":{"update_present_models":true}}'
```

Return `update_present_models` to `false` after the refresh. For Ollama server upgrades, change both the pinned version tag and verified multi-platform digest in role defaults or inventory, validate the release, back up model data if required, and deploy the runtime before the operations role.

Back up persistent application directories under `/opt/docker` before database, model, or image migrations. Stopping a Compose project does not remove bind-mounted data:

```bash
sudo systemctl stop docker-ollama-server
sudo tar -C /opt/docker -czf /path/to/ollama-server-backup.tgz ollama-server
sudo systemctl start docker-ollama-server
```

Choose a backup destination outside `/opt/docker` and protect it according to the data it contains.

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
- Inspect `systemctl status docker-ollama-server` and `docker logs ollama_server` for startup failures.
- Run `docker compose ... config --quiet` against rendered Compose before restarting a service.
- Role-specific variables, trust boundaries, migrations, and reset procedures are documented in each `roles/<role>/README.md`.
