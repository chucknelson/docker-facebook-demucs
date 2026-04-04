## Plan: CPU PyTorch 2 Refresh

Upgrade this repo to a CPU-first, PyTorch 2-based container while keeping the current clone-from-source workflow and the current pinned Demucs commit, because /home/chucknelson/development/docker-facebook-demucs/Dockerfile is already pinned to the latest upstream `adefossez/demucs` main commit `b9ab48c`. Keep the repo CPU-first, leave existing GPU knobs untouched unless they block the CPU path, and prefer a conservative pinned stack over chasing the newest available PyTorch 2 release.

**Steps**
1. Phase 1: Treat the current upstream Demucs revision as fixed. The first task is no longer selecting a newer Demucs commit; it is determining the newest practical CPU-only torch and torchaudio pair that works with the already-latest `b9ab48c` Demucs checkout in /home/chucknelson/development/docker-facebook-demucs/Dockerfile.
2. Phase 1: Define the CPU dependency baseline around that exact revision. Use CPU wheels from the PyTorch CPU index, keep numpy below 2, and pin a matched torch and torchaudio pair in the 2.1 line unless direct testing proves a newer compatible pair. This follows the working pattern seen in Demucs-Gui, which uses CPU-specific wheel indexes, git-sourced Demucs, and numpy below 2 rather than trying to force NumPy 2.
3. Phase 2: Update /home/chucknelson/development/docker-facebook-demucs/Dockerfile to make the CPU path explicit. Replace the current torch below 2, torchaudio below 2, numpy below 2 override with pinned CPU-oriented installs, add the PyTorch CPU extra index URL or equivalent pip configuration, and keep ffmpeg installed because Demucs and torchaudio still rely on it for mp3 handling.
4. Phase 2: Keep the current clone-and-checkout installation model and keep the checked out Demucs revision pinned at `b9ab48c`, since that is already the latest upstream main commit. Do not switch to the PyPI demucs package for this task because the user explicitly prefers the source-clone flow and upstream release cadence has lagged behind the git repo.
5. Phase 2: Revisit the image base only if needed for CPU clarity. Start by keeping the existing Ubuntu-based image if it simplifies ffmpeg and build tooling, then evaluate whether switching away from the Nvidia base image is low-risk. Because the user asked for CPU focus rather than removal of all GPU traces, base-image replacement is optional unless it is needed to make the CPU dependency installation cleaner or to avoid misleading documentation.
6. Phase 3: Update documentation in /home/chucknelson/development/docker-facebook-demucs/README.md and, if wording changes are needed, /home/chucknelson/development/docker-facebook-demucs/Makefile comments. Document that CPU is the supported/default path, note the pinned PyTorch 2 stack, explain that ffmpeg remains required, and adjust any wording that implies this repo is validated against the old torch below 2 stack.
7. Phase 3: Add validation during build and post-build testing. Keep the existing smoke test pattern in /home/chucknelson/development/docker-facebook-demucs/Dockerfile but validate it against the upgraded stack, then verify model loading, a short CPU separation run, and checkpoint compatibility using the existing mounted model cache under /home/chucknelson/development/docker-facebook-demucs/models.
8. Phase 4: If the latest upstream Demucs revision still fails on the selected torch and torchaudio versions, patch only the minimum compatibility surface in the vendored clone workflow. The first expected areas are torchaudio backend handling, audio loading, or import-time compatibility logic. Avoid broad local forks unless the failure is confirmed and narrowly scoped.

**Relevant files**
- `/home/chucknelson/development/docker-facebook-demucs/Dockerfile` — main upgrade point; update base install flow, dependency pins, and smoke test while keeping the existing latest Demucs commit.
- `/home/chucknelson/development/docker-facebook-demucs/README.md` — document CPU-first support, updated dependency expectations, and any changed usage notes.
- `/home/chucknelson/development/docker-facebook-demucs/Makefile` — likely no functional change, but verify help text and build description still match the CPU-first validated setup.
- `/home/chucknelson/development/docker-facebook-demucs/.github/copilot-instructions.md` — reference only; confirms CPU-first, platform-compatible direction and documentation requirements.

**Verification**
1. Build the image from scratch and confirm the dependency install resolves from CPU wheels without pulling CUDA-only packages.
2. Run a smoke check inside the image to print torch, torchaudio, numpy, and demucs versions and confirm the selected dependency set is the one intended.
3. Run the existing CLI smoke path on CPU using the bundled test audio and confirm model download and separation complete successfully.
4. Run a short real input from /home/chucknelson/development/docker-facebook-demucs/input through the Makefile CPU path and confirm output files are produced under /home/chucknelson/development/docker-facebook-demucs/output.
5. Verify existing checkpoint files under /home/chucknelson/development/docker-facebook-demucs/models/hub/checkpoints still load or, if model format changed, document whether they are redownloaded or need refresh.
6. Re-read the updated README and Makefile help text to ensure the supported path is clearly described as CPU-first with optional legacy GPU knobs left in place but not newly validated.

**Decisions**
- Included scope: CPU-first dependency and container refresh for newer PyTorch 2-era packages.
- Included scope: Keeping the current source-clone installation model for Demucs.
- Included scope: Keeping the current pinned Demucs commit because it is already the latest upstream main revision.
- Excluded scope: Broad GPU modernization, Intel, ROCm, or Nvidia-specific enablement work.
- Excluded scope: Moving to NumPy 2. The strongest available evidence still points to keeping numpy below 2 for Demucs-based stacks.
- Excluded scope: Re-architecting the Makefile interface unless CPU validation exposes a real problem.

**Further Considerations**
1. The core question is no longer which Demucs commit to use; it is which torch and torchaudio CPU pair this latest Demucs commit can actually sustain in practice.
2. Recommended torch target: start with torch 2.1.x and torchaudio 2.1.x CPU wheels. This matches the compatibility signals from upstream Demucs and the working pattern used by Demucs-Gui, while avoiding the extra risk of torchaudio 2.2+.
3. Optional cleanup after the upgrade is proven: if the repo should present itself as truly CPU-only, a follow-up can remove the Nvidia base image and GPU-oriented README and Makefile wording in a separate, lower-risk documentation and packaging pass.

**Completed Summary**
1. The container was updated to a CPU-first PyTorch 2 baseline using `torch==2.1.2`, `torchaudio==2.1.2`, and `numpy==1.26.4`, installed from the PyTorch CPU wheel index while keeping the existing Demucs source-clone workflow and pinned upstream commit `b9ab48c`.
2. The image kept `ffmpeg` and added `libsndfile1` plus Python `soundfile` support because the pinned Demucs revision did not save audio cleanly against torchaudio 2.1 CPU wheels using the upstream code path alone.
3. A narrow compatibility patch was applied to the vendored Demucs checkout during image build so the save path falls back cleanly when torchaudio 2.1 CPU backends reject the older `encoding` and `bits_per_sample` arguments or expose no writable backend. That patch logic was later moved into `scripts/patch_demucs_for_torchaudio21.py` to keep the Dockerfile readable.
4. Documentation and build text were updated so the repo now describes the validated path as CPU-first with optional Nvidia passthrough still present but not newly expanded in scope.
5. Validation completed successfully. `docker build --no-cache -t xserrat/facebook-demucs:latest .` passed with the build-time dependency smoke check and `python3 -m demucs -d cpu test.mp3` smoke run.
6. A real end-to-end CPU separation also completed successfully with mp3 output enabled using `make run track='01 Prayer.m4a' mp3output=true`. The run produced `bass.mp3`, `drums.mp3`, `other.mp3`, and `vocals.mp3` under `output/htdemucs/01 Prayer`, and container-side `ffprobe` confirmed the generated `vocals.mp3` stem was encoded as mp3 audio.
