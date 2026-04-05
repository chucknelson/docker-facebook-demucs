# Base image supports Nvidia CUDA but does not require it and can also run demucs on the CPU
FROM nvidia/cuda:13.2.0-base-ubuntu24.04

USER root
ENV TORCH_HOME=/data/models
ENV OMP_NUM_THREADS=1

# Install required tools
# Notes:
#  - build-essential and python3-dev are included for platforms that may need to build some Python packages (e.g., arm64)
#  - torchaudio >= 0.12 now requires ffmpeg on Linux, see https://github.com/facebookresearch/demucs/blob/main/docs/linux.md
RUN apt update && apt install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    git \
    nano \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Clone Demucs (now maintained in the original author's github space)
RUN git clone --single-branch --branch main https://github.com/adefossez/demucs /lib/demucs
WORKDIR /lib/demucs
# Checkout known stable commit on main
RUN git checkout b9ab48cad45976ba42b2ff17b229c071f0df9390

# Updated and pinned python dependency requirements for demucs
COPY demucs_override_requirements_minimal.txt requirements_minimal.txt
COPY demucs_override_requirements.txt requirements.txt

# Set up Python virtual environment, now required in Ubuntu 24.04
ENV VIRTUAL_ENV=/opt/demucs-venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
RUN python3 -m venv ${VIRTUAL_ENV}

# Install dependencies
RUN python3 -m pip install --no-cache-dir -e .

# Run once to ensure demucs works and trigger the default model download
RUN python3 -m demucs -d cpu test.mp3 
# Cleanup output - we just used this to download the model
RUN rm -rf separated

VOLUME /data/input
VOLUME /data/output
VOLUME /data/models

ENTRYPOINT ["/bin/bash", "--login", "-c"]
