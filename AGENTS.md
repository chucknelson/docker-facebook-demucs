# Docker Facebook Demucs Agent Notes

- Start with [README.md](README.md), [Makefile](Makefile), and [Dockerfile](Dockerfile) for project behavior and supported commands.
- Use `make build` to build the image and `make build-clean` only when you need to bypass Docker cache.
- Use `make run track=<filename>` to separate a file that already lives in `input/`; the `track` value should be the filename only.
- Use `make run-interactive gpu=true` for interactive container work; only `gpu` affects that target.
- Treat `input/`, `models/`, and `output/` as generated or user-data directories. Keep the tracked `.gitkeep` files intact.
- Do not duplicate upstream Demucs documentation here. Link to [README.md](README.md) or the upstream project when details already exist there.
- The container clones and pins upstream Demucs during image build, so changes to runtime behavior usually belong in [Makefile](Makefile) or [Dockerfile](Dockerfile), not in copied upstream source.