# ops_ollama_models

Reconciles an explicit inventory list of local Ollama models. It uses the Ollama CLI inside the running container to pull or remove models, so production operation does not require exposing the unauthenticated API.

```yaml
ops_ollama_models:
  models:
    - name: qwen3:8b
      type: llm
      state: present
      warm: true
      license: Apache-2.0
      source_url: https://ollama.com/library/qwen3:8b
    - name: bge-m3:latest
      type: embedding
      state: present
      warm: true
      license: MIT
      source_url: https://ollama.com/library/bge-m3
```

Unlisted models are retained. Set `state: absent` explicitly to remove one. `update_present_models: false` preserves idempotence; set it to `true` only during a deliberate model refresh.

Optional warm-up uses the Ollama API. Plain HTTP warm-up is restricted to loopback. Non-loopback warm-up requires verified HTTPS, making it suitable only after an authenticated TLS ingress is available. With warm-up enabled, the role verifies that all requested models remain loaded concurrently.

The defaults select `qwen3:8b` (5.2 GB, Apache 2.0) and multilingual `bge-m3:latest` (1.2 GB, MIT). Together with 4K context, one parallel request, Flash Attention, and a Q8 KV cache, they are sized for this lab's 12 GiB NVIDIA GPU.
