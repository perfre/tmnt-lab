# docker_ollama_server

Runs a pinned Ollama server with NVIDIA CDI GPU access. This role owns only the Compose runtime; `ops_ollama_models` owns model downloads, removals, and warm-up.

## Security and exposure modes

Ollama's local API has no built-in authentication. Safe non-lab defaults publish no host port. A production deployment must attach Ollama to an explicit external ingress network and place an authenticated TLS proxy, using a certificate from the local PKI, in front of it.

The committed local inventory publishes the plaintext API only on `127.0.0.1:11434`. Direct publishing is always restricted to loopback because the API is unauthenticated. Cloud execution and web-search features are disabled with `OLLAMA_NO_CLOUD=1`; pulling local model artifacts from the Ollama registry remains supported.

```yaml
docker_ollama_server:
  api:
    publish: true
    bind_address: 127.0.0.1
    port: 11434
  gpu:
    enabled: true
    devices:
      - nvidia.com/gpu=all
```

The container runs as UID/GID 1000, drops every capability, uses `no-new-privileges`, and has a read-only root filesystem. Models persist under `/opt/docker/ollama-server/models`.

## Production ingress example

```yaml
docker_ollama_server:
  api:
    publish: false
  ingress:
    enabled: true
    external: true
    network_name: secured_ai_ingress
```

The external network must be owned by the authenticated TLS proxy deployment. Never expose port 11434 directly on a production host.

## Verification

```bash
docker compose -f /opt/docker/ollama-server/compose.yml config --quiet
docker exec ollama_server ollama ps
curl --fail http://127.0.0.1:11434/api/version
```

The `curl` example is lab-only. Production verification must use HTTPS with CA and identity validation through the ingress endpoint.
