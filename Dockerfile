# Base image supports optional Nvidia CUDA, but the validated default path is CPU-only Demucs.
FROM nvidia/cuda:12.6.2-base-ubuntu22.04

USER root
ENV TORCH_HOME=/data/models
ENV OMP_NUM_THREADS=1
ARG TORCH_VERSION=2.1.2
ARG TORCHAUDIO_VERSION=2.1.2
ARG NUMPY_VERSION=1.26.4
ARG SOUNDFILE_VERSION=0.12.1

# Install required tools
# Notes:
#  - build-essential and python3-dev are included for platforms that may need to build some Python packages (e.g., arm64)
#  - torchaudio >= 0.12 now requires ffmpeg on Linux, see https://github.com/facebookresearch/demucs/blob/main/docs/linux.md
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    git \
    libsndfile1 \
    python3 \
    python3-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Clone Demucs (now maintained in the original author's github space)
RUN git clone --single-branch --branch main https://github.com/adefossez/demucs /lib/demucs
WORKDIR /lib/demucs
# Checkout known stable commit on main
RUN git checkout b9ab48cad45976ba42b2ff17b229c071f0df9390

# Keep the Dockerfile readable by applying the torchaudio 2.1 compatibility patch from a helper.
COPY scripts/patch_demucs_for_torchaudio21.py /tmp/patch_demucs_for_torchaudio21.py
RUN python3 /tmp/patch_demucs_for_torchaudio21.py

# Install a pinned CPU-first PyTorch 2 stack before the editable Demucs install.
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel \
    && python3 -m pip install --no-cache-dir \
        --index-url https://download.pytorch.org/whl/cpu \
        "torch==${TORCH_VERSION}" \
        "torchaudio==${TORCHAUDIO_VERSION}" \
    && python3 -m pip install --no-cache-dir \
        "numpy==${NUMPY_VERSION}" \
        "soundfile==${SOUNDFILE_VERSION}" \
    && python3 -m pip install --no-cache-dir -e .

# Print the pinned dependency stack and verify the image resolved CPU wheels.
RUN python3 - <<'PY'
import demucs
import numpy
import torch
import torchaudio

print(f"torch={torch.__version__}")
print(f"torchaudio={torchaudio.__version__}")
print(f"numpy={numpy.__version__}")
print(f"demucs_module={demucs.__file__}")

if torch.version.cuda is not None:
    raise SystemExit(f"Expected CPU-only torch wheel, found CUDA runtime {torch.version.cuda}")
PY

# Run once to ensure demucs works and trigger the default model download
RUN python3 -m demucs -d cpu test.mp3 
# Cleanup output - we just used this to download the model
RUN rm -r separated

VOLUME /data/input
VOLUME /data/output
VOLUME /data/models

ENTRYPOINT ["/bin/bash", "--login", "-c"]
