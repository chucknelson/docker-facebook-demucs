# Project Guidelines

## Compatibility
- Prefer changes that keep the project usable across common host platforms and CPU architectures when practical.
- Keep CPU execution as the default baseline. GPU acceleration should remain optional rather than required.
- Prefer accelerator choices and integration points that can extend beyond Nvidia/CUDA to AMD/ROCm and Intel when practical.
- Avoid introducing Nvidia/CUDA-only assumptions unless there is no practical alternative for the task.
- When GPU-specific behavior is necessary, preserve a documented non-GPU fallback or clearly document the limitation in the Dockerfile, Makefile, and README as needed.
- Favor vendor-neutral interfaces and configuration-driven runtime selection when they do not add significant complexity.

## Container Changes
- Prefer base images, package choices, and build steps that work on both GPU-capable and CPU-only hosts when feasible.
- Prefer container/runtime choices that do not unnecessarily block future support for non-Nvidia accelerators.
- Do not make the container unusable on non-Nvidia systems without explicitly documenting why the tradeoff is necessary.

## Documentation
- When changing platform or GPU behavior, update the README usage notes so users can tell what works by default, what is optional, and what host requirements apply.