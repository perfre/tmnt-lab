# docker_atlassian_lab

Runs single-node Jira Software Data Center and Confluence Data Center containers with an Nginx TLS proxy. PostgreSQL 17 is an external dependency owned by `docker_postgres`; both application databases and users are owned by `ops_postgres`. The committed local inventory binds HTTPS to `127.0.0.1`, uses synthetic database passwords, and creates a disposable local CA on the target. Synthetic `LAB_ONLY_*` credentials may only be used with loopback publishing.

## Licensing limitation

The containers are official Atlassian Data Center distributions, not a license bypass. Atlassian ended self-service Data Center trials for new customers on March 30, 2026. Existing Data Center customers can contact Atlassian for a 30-day evaluation license, and eligible commercial or academic self-managed license holders can generate free non-production developer licenses.

Without an eligible Jira and Confluence license, the containers can start but setup cannot be completed. Atlassian Cloud Free is not self-hosted and cannot be substituted into this Docker role.

- Jira trial policy: <https://confluence.atlassian.com/adminjiraserver/get-a-jira-data-center-trial-license-1595114470.html>
- Confluence trial policy: <https://support.atlassian.com/confluence/kb/how-to-generate-an-evaluation-or-trial-license-for-confluence-data-center/>
- Data Center developer licensing: <https://www.atlassian.com/licensing/data-center>
- Official container registry reference: <https://support.atlassian.com/jira/kb/downloading-atlassian-docker-images-and-dependencies-without-use-of-docker-hub/>

## Requirements

- Docker Engine with the Compose v2 plugin
- `community.docker` and `community.crypto` Ansible collections
- The `docker_postgres` and `ops_postgres` roles deployed first
- At least 8 GiB of memory available to Docker is recommended for both applications and the shared database
- An eligible Jira Software Data Center and Confluence Data Center license

## Configuration

All role configuration lives under `docker_atlassian_lab`.

```yaml
docker_atlassian_lab:
  bind_address: 127.0.0.1
  jira:
    https_port: 8443
  confluence:
    https_port: 8444
  database:
    network:
      name: tmnt_postgres
      external: true
```

The local inventory database passwords are intentionally synthetic. Do not reuse them. Application administrator accounts and license keys are entered through the Atlassian setup wizards and must match the inventory profile and licensing terms.

## Deploy and trust the disposable CA

Deploy the shared database bootstrap and application roles (the normal unfiltered playbook does this in dependency order):

```bash
/usr/local/bin/deploy services.yml \
  --tags docker_postgres,ops_postgres,docker_atlassian_lab
```

The generated public CA certificate is `/opt/docker/atlassian-lab/pki/ca.crt` on the target host. Import only that public certificate into clients that should trust this inventory profile. Never distribute or trust the disposable local-profile CA broadly.

Open:

- `https://jira.localhost:8443`
- `https://confluence.localhost:8444`

Complete each setup wizard with its own eligible evaluation or developer license. Use the database settings already supplied through the container environment.

## Verification

```bash
sudo docker compose --env-file /opt/docker/atlassian-lab/lab.env \
  -f /opt/docker/atlassian-lab/compose.yml config --quiet
sudo systemctl status docker-atlassian-lab
openssl s_client -verify_return_error \
  -CAfile /opt/docker/atlassian-lab/pki/ca.crt \
  -connect jira.localhost:8443 -servername jira.localhost </dev/null
ss -lnt | grep -E '127.0.0.1:(8443|8444)'
```

The Jira and Confluence containers intentionally retain writable application filesystems because Atlassian's startup scripts render Tomcat configuration there. They still run as the documented image UIDs, drop all capabilities, use `no-new-privileges`, and expose no direct application or database ports. Production use remains blocked until database TLS, protected secret sourcing, certificate trust, backup/restore, and license handling are finalized for that inventory.

## Reset or remove

This destroys Jira, Confluence, and disposable-PKI lab data. It does not remove the shared PostgreSQL service or its Jira and Confluence databases:

```bash
sudo systemctl disable --now docker-atlassian-lab
sudo docker compose --env-file /opt/docker/atlassian-lab/lab.env \
  -f /opt/docker/atlassian-lab/compose.yml down --remove-orphans
sudo rm -rf /opt/docker/atlassian-lab
```

Confirm the path before removing it. Remove the disposable CA from browser and operating-system trust stores after teardown. The role does not automate destructive teardown or license removal.

If upgrading from the earlier embedded-database layout, export both `/opt/docker/atlassian-lab/postgres-jira` and `/opt/docker/atlassian-lab/postgres-confluence` before deployment and import them into the shared service. This refactor deliberately leaves those old data directories untouched.
