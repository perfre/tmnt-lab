# Repository Agent Instructions

## Mission and scope

Maintain this repository as an idempotent Ansible deployment for containerized lab services. Docker Compose is the runtime contract, and narrowly scoped Ansible roles are the only supported deployment mechanism.

Security is a design requirement. New and changed services must use authenticated encryption, least privilege, explicit trust, and secret-safe configuration by default. This baseline improves security posture but does not by itself certify the repository against a regulatory framework.

These instructions apply to the whole repository. If a future subdirectory adds an `AGENTS.md`, follow both files and let the more specific file govern only that subtree.

## Existing layout and conventions

- `services.yml` is the deployment entry point and maps inventory groups to roles.
- `inventory-local/` is lab inventory, not a secret store.
- `roles/service_docker` owns Docker Engine installation and daemon configuration.
- Each `roles/docker_<service>` role owns one Compose project, including defaults, validation, rendered configuration, a Compose template, a systemd unit, handlers, metadata, and role documentation.
- Role inputs are namespaced beneath a single mapping named after the role, such as `docker_netbox`.
- Runtime files are rendered below the role's `project_dir`, normally `/opt/docker/<service>`; do not maintain a second, manually operated Compose deployment for the same service.
- Use `ansible.builtin.*` and `community.docker.docker_compose_v2`; keep task and handler names descriptive and stable.

Treat insecure existing values as remediation debt, not as patterns to copy. In particular, do not propagate plaintext passwords, `latest` tags, wildcard allowed-host settings, disabled TLS, unverified TLS, or globally disabled SSH host-key verification. When a task touches the affected security path, improve it within scope or clearly report the remaining debt.

## Required work process

### Local Ansible environment

This WSL lab uses the repository bootstrap in `ansible-setup.sh` and `ansible-setup.env`:

- Ansible is installed in a shared Python 3.12 virtual environment at `/opt/ansible`.
- System-wide wrappers live in `/usr/local/bin`, including `/usr/local/bin/ansible-playbook` and `/usr/local/bin/deploy`.
- The `deploy` wrapper activates the shared virtual environment and runs `ansible-playbook -i ~/dev/tmnt-lab/inventory-local/ --diff`.
- Use `/usr/local/bin/deploy services.yml ...` for local lab role testing when exercising the disposable WSL lab inventory; add `-K` when Ansible needs a sudo prompt, and use the narrower syntax/check commands below when a full local run is unnecessary.
- Treat local sudo credentials as secrets. Do not write them into repository files, command lines, logs, facts, task names, diffs, commits, or documentation; request them interactively only when needed.
- Do not edit the external WSL system outside this repository without asking the user first. Repository file changes are allowed when these instructions are followed.

### Git hygiene

- Before editing files, run `git pull --ff-only` to check for upstream changes and preserve any existing local edits.
- If the worktree already contains edited, staged, untracked, or otherwise pending files, ask whether those changes should be included in the next commit before committing.

### Architectural decision gate

Before making files or changing runtime state for a request that introduces or materially changes architecture, present two or three viable options to the user. Explain the important tradeoffs, mark one path as recommended, and wait for the user's selection before proceeding. Read-only repository and environment discovery is allowed before the options because it makes them concrete. Do not treat minor implementation details or an already approved design as a new decision gate.

When a decision is approved, keep these instructions and the root `README.md` synchronized with any lasting convention, ownership boundary, deployment mode, or security choice created by that decision.

Before changing a service role:

1. Read its `README.md`, `defaults/main.yml`, `tasks/main.yml`, `handlers/main.yml`, `meta/main.yml`, and all relevant templates.
2. Trace its inventory group and play in `services.yml` and `inventory-local/hosts.yml`.
3. Identify trust boundaries, published ports, stored data, secrets, certificate names, health checks, and required Linux capabilities.
4. Prefer a small extension of the existing role contract. Do not add ad hoc host commands, standalone production Compose files, or unrelated responsibilities to a role.
5. Preserve idempotence and check-mode usefulness. Inspect the diff for leaked secrets before reporting completion.

Do not silently rewrite unrelated roles. If a secure implementation needs a shared primitive, add a narrowly scoped role or an explicit role dependency with a documented variable interface.

## Role and deployment boundaries

Role names must use a stable, descriptive prefix:

- `docker_<service>` for every role that owns a Docker Compose application runtime;
- `service_<service>` for host-level service installation or daemon configuration;
- `ops_<operation>` for backup, restore, migration, rotation, maintenance, or other operational workflows;
- `security_<control>` or `pki_<function>` for reusable host-security and certificate-authority responsibilities;
- another clear domain prefix, such as `network_` or `monitoring_`, only when it describes the role more accurately.

Use lowercase snake case and name the role for the single resource or responsibility it owns. Do not create unprefixed roles or vague names such as `common`, `utils`, or `setup`. Renaming an existing role requires updating its directory, variable namespace, playbook tag, documentation, and all consumers in one change.

Every new Compose deployment must have its own `roles/docker_<service>` role containing, as applicable:

- `defaults/main.yml`: safe, non-secret defaults and the complete public variable shape;
- `tasks/main.yml`: input assertions, directories, secret/certificate preparation, templates, service unit, and Compose reconciliation;
- `templates/compose.yml.j2`: the complete runtime definition;
- `templates/docker-<service>.service.j2`: boot lifecycle matching the existing systemd pattern;
- `handlers/main.yml`: restarts only when rendered runtime inputs change;
- `meta/main.yml`: supported Ansible version, platforms when relevant, and explicit dependencies;
- `README.md`: variables, ports, data paths, trust model, secret source, certificate lifecycle, deployment example, and verification steps.

Add the role to the correct inventory group in `services.yml` with a same-named tag. Keep host preparation in `service_*` roles and application runtime in `docker_*` roles. A service role must not mutate another service's project directory, Compose project, data, secrets, or systemd unit.

Shared resources such as an external Docker network or PKI trust bundle require an explicit owner. Consumers may reference them through documented variables but must not recreate, rotate, or delete them implicitly. Destructive migrations and certificate-authority rotation require a documented migration and rollback path.

`inventory-local/hosts.yml` is the canonical disposable-lab database bootstrap manifest. When a system gains or loses a relational backend, update the matching `ops_mariadb` or `ops_postgres` user/database entries and the application's connection variables in that same change. The database runtime role must execute before its operations role, and both must execute before consumers. Conspicuously synthetic `LAB_ONLY_*_DO_NOT_REUSE` values are permitted in this manifest solely for localhost lab mode; real credentials remain prohibited.

Current architectural decisions:

- Keep one deployment playbook, `services.yml`, and express lab versus production behavior through separate inventories; do not fork near-duplicate lab and production playbooks.
- Separate stateful service runtimes from their operational content. Database containers live in `docker_mariadb`/`docker_postgres`, database users and schemas in `ops_mariadb`/`ops_postgres`, the Ollama runtime in `docker_ollama_server`, and model lifecycle in `ops_ollama_models`.
- Keep shared database application networks internal. When an operations role needs host-side administrative TCP, expose it through a separate database-owned admin network and bind lab listeners to loopback; production exposure still requires verified TLS and approved secret handling before relaxing lab assertions.
- Use NVIDIA Container Device Interface (CDI) as the GPU contract. `service_docker` owns NVIDIA Container Toolkit installation and CDI refresh, never the physical-host GPU driver. GPU consumers request explicit `nvidia.com/gpu=...` devices.
- Never expose Ollama's unauthenticated API directly in production. Lab mode may publish it on loopback; production attaches it to a separately owned authenticated TLS ingress network.

## Local PKI and TLS baseline

Use the repository's local PKI for every HTTP API, web UI, database, message bus, metrics endpoint, webhook receiver, and other protocol that supports TLS. Plaintext is acceptable only inside an isolated test fixture that is not published from the container network; label and document that exception.

PKI responsibilities must be separated:

- A dedicated PKI role owns CA initialization, policy, public trust distribution, issuance or enrollment, renewal, and revocation artifacts.
- Service roles request or consume a unique leaf certificate and mount only that service's private key plus the required chain.
- Never commit or template a CA private key. Keep it offline or encrypted in an approved secret backend. Do not copy it into application containers.
- Prefer generating leaf private keys on the target. Store private keys as `root:root` mode `0600`, certificates and CA bundles as mode `0644`, and containing directories no broader than `0750`.
- Mark tasks that handle private key or secret material with `no_log: true`. Do not expose values through task names, diffs, command arguments, facts, logs, or debug output.

Certificate requirements:

- Include every actual DNS name and IP address in SANs; never rely on the Common Name for identity.
- Set correct EKUs (`serverAuth`, and `clientAuth` only where mutual TLS is required), key usage, and basic constraints.
- Use SHA-256 or stronger and modern key types supported by all consumers. Prefer ECDSA P-256/P-384; use RSA 3072+ when compatibility requires RSA.
- Use short-lived leaf certificates with automated renewal. Default to no more than 397 days and renew well before expiry; document any shorter application-specific policy.
- Require TLS 1.2 or newer and prefer TLS 1.3. Disable SSL, TLS 1.0/1.1, weak ciphers, compression, and insecure renegotiation.
- Verify hostname and certificate chain for every client. Never add `verify: false`, `--insecure`, trust-all callbacks, or equivalent bypasses.
- Mount trust bundles and certificates read-only. Restart or reload only the affected service after a renewed certificate changes.
- Health checks must use HTTPS with CA validation once TLS is enabled. A TCP-only check is acceptable only when it cannot falsely claim application readiness.

Bind a TLS endpoint directly in the application when it is well supported. Otherwise use a dedicated reverse-proxy role that terminates TLS, redirects HTTP to HTTPS, supplies security headers, and publishes the only external web port. Bind any plaintext upstream to an internal Compose network or loopback, never all host interfaces.

Mutual TLS is required for privileged machine-to-machine administration and secret-management interfaces unless the product provides an equally strong, documented identity mechanism. Certificate rotation must not require rebuilding an image.

## Localhost lab mode

Roles may expose an explicit `<role_name>.lab_mode` for disposable testing without Ansible Vault. Lab mode is an exception profile, not a production compatibility mode, and must never be inferred automatically.

When `lab_mode: true`, the role must:

- assert that `ansible_host` resolves explicitly to `localhost`, `127.0.0.1`, or `::1`, or that an equivalent local connection is provably in use;
- bind every published TCP/UDP port to a loopback address, never `0.0.0.0` or a LAN interface;
- use only generated throwaway secrets or conspicuously synthetic, role-specific lab values that cannot be mistaken for real credentials;
- reject user-supplied production-looking credentials and document that lab credentials must never be reused;
- keep backends on internal Compose networks and retain the normal least-privilege container controls;
- generate a disposable local CA and leaf certificates on the target when TLS is needed, protect their private keys, and never reuse that CA outside the lab deployment;
- keep secret-bearing output redacted with `no_log`/`diff: false` even though the credentials are synthetic;
- label data, certificates, accounts, and licenses as disposable and provide a clear teardown/reset procedure.

Lab mode may avoid Vault, external secret managers, public DNS, and a production PKI, but it may not disable TLS verification, use real credentials, publish services beyond loopback, bypass product licensing, or weaken the non-lab defaults. If the localhost condition is not satisfied, fail before creating files or containers.

## Secrets and sensitive data

- Never commit real passwords, tokens, private keys, recovery keys, unseal material, SNMP credentials, or Ansible connection credentials.
- Defaults must use empty values or unmistakable invalid placeholders. Assert that required secrets are present and reject known placeholders before deployment.
- Source secrets from Ansible Vault or an approved external secret manager. Commit only encrypted Vault data, public certificates, and non-sensitive examples.
- Prefer Compose secrets and application `_FILE` settings. Environment variables are a fallback because they can be exposed by container inspection.
- Render unavoidable secret files as `root:root` mode `0600`; use `0640` only when a documented runtime group needs access. Never render secret-bearing files as `0644`.
- Keep secret values out of Compose labels, image build arguments, Dockerfiles, URLs, shell command lines, and systemd unit text.
- Add `no_log: true` at the smallest task boundary that reliably prevents disclosure. Do not apply it so broadly that ordinary failures become impossible to diagnose.
- Use separate credentials per service and per trust boundary. Grant only the database, API, or filesystem permissions required by that consumer.
- Do not place credentials in `inventory-local/hosts.yml`. Local convenience does not make a committed secret safe.

## Docker Compose security baseline

For every new service, and for existing services when the relevant configuration is changed:

- Pin images to an intentional version. Prefer an immutable digest for security-sensitive services; never introduce a floating `latest` tag without a documented, lab-only exception.
- Run as a documented non-root UID/GID when the image supports it. Never use `privileged: true`.
- Set `security_opt: [no-new-privileges:true]`, drop all Linux capabilities, and add back only capabilities proven necessary. Document every added capability.
- Use a read-only root filesystem where supported, with explicit writable volumes or `tmpfs` mounts for required paths.
- Do not mount `/var/run/docker.sock`, the host root filesystem, device nodes, or broad host paths unless the task explicitly requires it and the security impact is documented.
- Put databases, caches, and backends on internal networks and do not publish their ports. Publish only required ingress ports, using structured long syntax and an explicit host address when exposure should be limited.
- Use separate frontend and backend networks when that materially narrows reachability. Avoid `network_mode: host`.
- Add a meaningful health check with bounded interval, timeout, retries, and start period. Use health-based dependency conditions when startup ordering matters.
- Set a restart policy, bounded logging/rotation, and reasonable CPU, memory, and process limits appropriate for the service.
- Mount configuration and certificate material read-only. Make persistent data paths explicit and back-upable.
- Do not bake secrets, locally issued certificates, or environment-specific configuration into images.
- Keep `container_name` optional unless stable cross-project naming is truly required; prefer Compose service DNS on scoped networks.

Dockerfiles must use a pinned, minimal trusted base, install only required packages, verify downloaded artifacts, combine package cleanup with installation, run as non-root, and include a `.dockerignore` when a build context could contain unrelated or sensitive files.

## Ansible implementation standards

- Use YAML starting with `---`, two-space indentation, booleans as `true`/`false`, quoted file modes, and fully qualified collection names.
- Put overridable values in the role namespace. Do not introduce unscoped variables or depend on ambient variables from another role.
- Validate type, allowed values, required fields, unsafe placeholders, port ranges, path constraints, and mutually dependent TLS settings with `ansible.builtin.assert` before mutating the host.
- Do not introduce deprecated or announced-future-deprecated Ansible features. Treat deprecation warnings as defects to fix in scope; use `ansible_facts["fact_name"]` instead of top-level injected fact variables such as `ansible_os_family`.
- Use modules instead of `command` or `shell`. If a command is unavoidable, make it injection-safe and define `changed_when`, `failed_when`, and check-mode behavior.
- Use handlers for restarts. Template tasks that affect runtime behavior must notify the appropriate handler; unrelated changes must not restart services.
- Set owner, group, and mode on every created directory and file. Use least privilege and preserve application UID/GID requirements.
- Keep tasks idempotent. A second identical run must report no changes. Never use unconditional restarts or unconditional certificate renewal.
- Use `become: true` at the play or smallest necessary task scope. Do not weaken host security controls to make automation easier.
- Avoid logging secret-bearing diffs. If a template contains secrets, set `diff: false` on that task in addition to appropriate `no_log` handling.
- Keep role defaults usable as documentation, not as production credentials. Document every public variable added or changed.
- Prefer explicit dictionaries and lists over encoded strings, especially for ports, mounts, networks, health checks, and certificate SANs.

## Validation and evidence

Run the narrowest relevant checks, then expand according to risk. At minimum for Ansible or role changes:

```bash
ansible-playbook -i inventory-local/hosts.yml services.yml --syntax-check
ansible-lint .
```

If `ansible-lint` is unavailable, report that rather than claiming it passed. For a changed role, also perform a check-mode run limited to a safe test host when the environment supports it. Never use check mode as proof of runtime correctness.

For localhost lab role changes, test edits against the local WSL lab with the installed wrapper unless the user explicitly says not to:

```bash
/usr/local/bin/deploy services.yml --tags <role_tag> --limit <safe-host>
```

After a local lab deploy, verify the affected functionality, inspect service health/logs where relevant, and fix problems discovered during testing unless the user explicitly says not to continue.

If testing requires wiping or reinitializing an existing MariaDB or PostgreSQL backend volume to verify database backend redeployment, ask the user first unless the requested task already explicitly approved that destructive reset. Non-destructive runs against existing database volumes may proceed under the normal validation rules.

Before deployment, validate the rendered Compose model with `docker compose config --quiet`. For security or TLS changes, verify all of the following with non-secret evidence:

- a second Ansible run is idempotent;
- containers become healthy and systemd reports the Compose unit active;
- only intended host ports listen;
- the TLS chain and hostname validate against the local CA;
- TLS 1.0 and 1.1 are rejected;
- unauthenticated or unauthorized access is rejected;
- private-key and secret-file permissions are correct;
- renewal changes the leaf certificate and reloads only the affected service;
- rollback restores the previous working configuration without data loss.

Useful commands include `ansible-playbook --check --diff --limit <safe-host>`, `docker compose config --quiet`, `openssl s_client -verify_return_error -CAfile <ca.pem> -connect <host>:<port> -servername <dns-name>`, and `ss -lntup`. Redact credentials, tokens, private keys, and sensitive inventory values from all captured output.

## Documentation and change acceptance

Maintain a tidy root `README.md` for users who have no prior knowledge of the repository. Keep it concise but complete and update it with every deployment-affecting change. It must include:

- repository purpose and architecture;
- prerequisites and dependency installation;
- exact lab bootstrap, full deployment, selective-role, verification, upgrade, backup, and teardown commands;
- production inventory and secret/PKI expectations, deployment commands, and an explicit list of roles that remain lab-only or otherwise blocked from production;
- role naming and navigation guidance;
- ports, URLs, persistent-data locations, and the difference between runtime (`docker_*`), host service (`service_*`), and operations (`ops_*`) roles;
- warnings before destructive actions or data migrations and pointers to the affected role README.

Never describe a lab-only configuration as production-ready. If the repository lacks a required production control, document the gap and the condition that must be met rather than supplying an insecure workaround.

A deployment change is complete only when the role, `services.yml`, inventory example, and role README agree. Document security-relevant defaults, exposed ports, data ownership, backup implications, PKI names, renewal behavior, secret source, upgrade procedure, and rollback steps.

When a role has been created or modified and the required tests pass, create a git commit with a clear message describing the role and behavior changed, then push it to the configured remote. Do not include secrets in commit messages, commit bodies, diffs, or pushed history; if push is unavailable, report the exact reason.

Do not claim compliance merely because TLS is present. In the final report, distinguish:

- controls implemented and verified;
- checks not run or unavailable;
- compatibility or lab-only exceptions;
- known security debt that remains outside the requested scope.

## Code review rules

- Flag any new plaintext secret, private key, default credential, `no_log` omission around secret material, or secret-bearing file mode broader than required. Safe path: use Vault/external secrets, invalid defaults, assertions, and restricted files.
- Flag new plaintext published services, disabled certificate verification, incomplete SANs, or TLS below 1.2. Safe path: issue a service leaf certificate from the local PKI and validate the chain and hostname.
- Flag floating image tags, privileged containers, root execution without justification, added capabilities, Docker socket mounts, host networking, or public backend ports. Safe path: pin the image and apply the least-privilege Compose baseline.
- Flag runtime resources created outside a scoped Ansible role or role changes that mutate another role's resources. Safe path: add a dedicated role or a documented shared dependency and reconcile it through `services.yml`.
- Flag changes without syntax validation, rendered Compose validation, security-specific verification, or documentation. Safe path: run the applicable checks and report exact evidence and omissions.

An exception must be explicit, narrowly scoped, documented next to the setting and in the role README, limited to the lab environment, assigned a removal condition, and never represented as a secure production default.
