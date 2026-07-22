# Linux NVIDIA EXLA Validation

This report records the first end-to-end validation of Obscura Examples on a
Linux NVIDIA host. It is a runtime compatibility and application smoke report,
not an authoritative accuracy or capacity benchmark.

## Result

Obscura Examples successfully ran `:fast`, `:balanced`, and `:accurate` on a
Lightning AI Studio with a Tesla T4. The two model-backed profiles used an
explicit EXLA CUDA client. Runtime evidence included a CUDA-backed Nx matrix
operation, correct Obscura detections, model-serving reuse, and the expected
`Mali` fingerprint from the conditional Jean-Baptiste location cascade.

## Environment

Validation date: 2026-07-22.

| Component | Observed value |
|---|---|
| GPU | NVIDIA Tesla T4, compute capability 7.5 |
| GPU memory | 15,360 MiB |
| Driver | 580.159.03 |
| CUDA driver/runtime/toolkit | 13.0 |
| cuDNN | 9.14.0 |
| NCCL | 2.28.3 |
| NVSHMEM compatibility runtime | 3.3.24, isolated under the Studio home directory |
| Erlang | OTP 29.0.3 / ERTS 17.0.3 |
| Elixir | 1.20.2 compiled for OTP 29 |
| Nx | 0.12.1 |
| EXLA | 0.12.0 |
| XLA archive | 0.10.0, `x86_64-linux-gnu-cuda13` |

The machine also had NVSHMEM 3.7.2 installed globally. That package exposes
transport ABI 6, while the precompiled XLA 0.10.0 CUDA 13 archive requires
`nvshmem_transport_ibrc.so.3`. No unsafe ABI symlink was used. NVSHMEM 3.3.24
was extracted into an isolated directory and placed first in
`LD_LIBRARY_PATH`. NVIDIA 3.3.24 also restores SM75 support required by the T4.

## Reproduction

Install the optional EXLA dependency and select the CUDA version reported by
`nvcc --version`:

```sh
export OBSCURA_EXAMPLES_EXLA=1
export XLA_TARGET=cuda13
export ELIXIR_ERL_OPTIONS="+sssdio 128"

mix clean
mix deps.get
mix compile --warnings-as-errors
```

For a CUDA 13 image whose current NVSHMEM package exposes transport ABI 6,
obtain the compatible ABI 3 runtime without replacing the system package:

```sh
mkdir -p "$HOME/.local/opt/nvshmem-3.3.24"
cd /tmp
apt-get download libnvshmem3-cuda-13=3.3.24-1
dpkg-deb -x \
  libnvshmem3-cuda-13_3.3.24-1_amd64.deb \
  "$HOME/.local/opt/nvshmem-3.3.24"

export NVSHMEM_COMPAT_DIR="$HOME/.local/opt/nvshmem-3.3.24/usr/lib/x86_64-linux-gnu/nvshmem/13"
export LD_LIBRARY_PATH="$NVSHMEM_COMPAT_DIR:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda/lib64"
```

Confirm that the compatibility directory provides transport ABI 3:

```sh
find "$NVSHMEM_COMPAT_DIR" -name 'nvshmem_transport_ibrc.so*' -print
```

Then prove the EXLA client before preparing a model:

```sh
mix run --no-start -e '
{:ok, _} = Application.ensure_all_started(:exla)
platforms = EXLA.Client.get_supported_platforms()
client = EXLA.Client.fetch!(:cuda)
IO.inspect(platforms, label: "supported_platforms")
IO.inspect(Map.take(Map.from_struct(client), [:name, :platform, :device_count]),
  label: "cuda_client")
'
```

The observed output was `%{host: 4, cuda: 1}` with a `:cuda` client and one
device. XLA identified a Tesla T4 and loaded cuDNN 9.14.0.

An explicit 2048 by 2048 matrix operation returned an `EXLA.Backend` tensor,
transferred successfully to `Nx.BinaryBackend`, and reported a 16,777,216-byte
peak CUDA allocation. This proves actual device execution beyond dependency or
client detection.

## CPU Baseline

Before enabling EXLA, the dependency-light `:fast` profile completed the
default LiveView detection request in 32 ms. Phoenix served the workbench and
established a LiveView WebSocket through Lightning's port proxy.

## Balanced Profile

Preparation downloaded a 1,417.56 MB TNER checkpoint and produced a reusable
runtime. The first request initialized and compiled the CUDA computation.

Input:

```text
Rachel works at Google in Paris. Contact her at info@example.com or +1 202-555-0188. Visit example.org. Card 4111 1111 1111 1111.
```

Observed detections:

| Entity | Text | Byte range | Score |
|---|---|---:|---:|
| PERSON | Rachel | 0-6 | 0.744 |
| ORGANIZATION | Google | 16-22 | 1.000 |
| LOCATION | Paris | 26-31 | 0.993 |
| EMAIL | info@example.com | 48-64 | 0.850 |
| PHONE | +1 202-555-0188 | 68-83 | 0.750 |
| DOMAIN | example.org | 91-102 | 0.700 |
| CREDIT CARD | 4111 1111 1111 1111 | 109-128 | 1.000 |

Cold LiveView request latency was 4,639 ms. Three identical warm requests were
902, 909, and 897 ms: mean 902.7 ms, median 902 ms, and a 12 ms range.

Single exploratory runs also completed for every operator:

| Operator | LiveView latency |
|---|---:|
| Replace | 1,198 ms |
| Redact | 900 ms |
| Mask | 1,007 ms |
| Hash | 1,460 ms |
| Pseudonymize | 957 ms |

These one-off operator values prove behavior but are not an operator benchmark.

The BEAM process appeared in `nvidia-smi` with 13,550 MiB. This value primarily
reflects EXLA's BFC pool reservation and must not be presented as the model's
weight footprint.

## Accurate Profile

Preparation reused the TNER assets and downloaded the 1,417.43 MB
Jean-Baptiste checkpoint. A normal input whose primary model found `Paris`
completed its first request in 2,981 ms. Three warm requests took 890, 1,062,
and 908 ms: mean 953.3 ms and median 908 ms.

The secondary location path was exercised with a synthetic multiline sample.
It detected `Mali` as `LOCATION` at bytes 75-79 with a displayed score of
1.000, matching the authoritative unrounded score of approximately 0.9996.
This is the expected fingerprint when the primary model has no accepted
location and the Jean-Baptiste secondary model runs.

The first secondary-path request took 3,782 ms. Four final warm repetitions
with organization also requested took 1,793, 1,789, 1,836, and 1,811 ms: mean
1,807.3 ms, median 1,802 ms, and a 47 ms range. The triggered cascade was about
2.0 times slower than the measured `:balanced` warm request.

The model did not accept the synthetic organization `Demystdata`. This is a
recognizer miss, not a backend failure. The stable cascade recovers locations
only and does not run a second organization recognizer.

## Limitations

- This run used one Tesla T4 host and one LiveView session.
- It did not run the authoritative three-dataset accuracy matrix.
- It did not measure concurrency, throughput, p95/p99 latency, sustained load,
  process recovery, or bounded memory growth.
- LiveView request time includes application overhead and is not isolated model
  inference time.
- GPU memory shown by `nvidia-smi` includes EXLA's allocator pool.
- The NVSHMEM ABI workaround is specific to XLA 0.10.0 CUDA 13 and images that
  ship an incompatible newer transport ABI. Recheck this requirement when XLA
  changes.

Within those limits, the result proves that the public model preparation and
inference workflow works on Linux with an NVIDIA T4 and EXLA CUDA.
