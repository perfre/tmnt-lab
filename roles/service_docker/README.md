# service_docker

Installs the official Docker repository and the latest Docker CE packages with conservative daemon defaults.

All inventory/default configuration lives under `service_docker`.

```yaml
service_docker:
  state: latest
  channel: stable
  users:
    - crypt
  daemon:
    log-driver: json-file
    log-opts:
      max-size: 10m
      max-file: "3"
    storage-driver: overlay2
    live-restore: true
  gpu:
    enabled: true
    vendor: nvidia
    mode: cdi
    device: nvidia.com/gpu=all
```

## NVIDIA GPU support

GPU support is disabled by default. When enabled, the role installs the current stable NVIDIA Container Toolkit from NVIDIA's official repository, enables automatic CDI specification refresh, and verifies the requested CDI device. It supports Debian/Ubuntu and RedHat-family hosts.

The role never installs an NVIDIA display or CUDA driver. Install the physical-host driver first. On WSL, install the NVIDIA driver in Windows only; `/dev/dxg` is then provided to Linux by WSL.

Containers request the configured device with Compose CDI syntax:

```yaml
devices:
  - nvidia.com/gpu=all
```

Verify the host after deployment:

```bash
nvidia-ctk cdi list
docker run --rm --device nvidia.com/gpu=all ubuntu:24.04 nvidia-smi -L
```
