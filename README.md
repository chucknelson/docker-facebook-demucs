# Docker Facebook Demucs
This repository dockerizes [Demucs](https://github.com/adefossez/demucs)
to split music tracks into different tracks (bass, drums, voice, others).

The supported default path is CPU-first. The image keeps the current source-clone workflow pinned to Demucs commit `b9ab48c`, installs CPU PyTorch wheels from the PyTorch CPU index, and keeps `ffmpeg` in the image because Demucs and `torchaudio` still rely on it for mp3 handling.

## Usage
### Clone this repository
```bash
git clone https://github.com/xserrat/docker-facebook-demucs.git demucs
```
### Split a music track
1. Copy the track you want to split into the `input` folder (e.g., `input/mysong.mp3`).
2. Execute `demucs` via the `run` job in the `Makefile`, specifying the `track` argument with only the name of the file:
```bash
make run track=mysong.mp3
```

This process will take some time the first time it is run, as the execution will:
* Download the Docker image that is setup to run the `facebook demucs` script.
* Download the pretrained models.
* Execute `demucs` to split the track.

Subsequent runs will not need to download the Docker image or download the models, unless the model specified has not yet been used.

The validated dependency baseline in the image is `torch==2.1.2`, `torchaudio==2.1.2`, and `numpy==1.26.4`.

#### Options
The following options are available when splitting music tracks with the `run` job:

Option | Default Value | Description
--- | --- | ---
`gpu`           | `false` | Enable Nvidia CUDA support (requires an Nvidia GPU).
`model`         | `demucs`| The model used for audio separation. See https://github.com/facebookresearch/demucs#separating-tracks for a list of available models to use.
`mp3output`     | `false` | Output separated audio in `mp3` format instead of the default `wav` format.
`shifts`        | `1`     | Perform multiple predictions with random shifts (a.k.a the shift trick) of the input and average them. This makes prediction `SHIFTS` times slower. Don't use it unless you have a GPU.
`overlap`       | `0.25`  | Control the amount of overlap between prediction windows. Default is 0.25 (i.e. 25%) which is probably fine. It can probably be reduced to 0.1 to improve separation speed.
`jobs`          | `1`     | Specify the number of parallel jobs to run during separation. This will multiply the amount of RAM used by the same number, so be careful!
`splittrack`    |         | Individual track to split/separate from the others (e.g., you only want to separate drums). Valid options are `bass`, `drums`, `vocals` and `other`. Other values may be allowed if the model can separate additional track types.

Example commands:
```bash
# Use the "fine tuned" demucs model
make run track=mysong.mp3 model=htdemucs_ft

# Enable optional Nvidia CUDA support and output separated audio in mp3 format
make run track=mysong.mp3 gpu=true mp3output=true
```

### Run Interactively

To experiment with other `demucs` options on the command line, you can also run the Docker image interactively via the `run-interactive` job. Note that only the `gpu` option is applicable for this job.

Example:
```bash
make run-interactive gpu=true
```

## Building the Image

The Docker image can be built locally via the `build` job:
```bash
make build
```

To force Docker to rebuild without using layer cache:
```bash
make build-clean
```

The build performs a dependency smoke check during image creation, applies a small torchaudio 2.1 compatibility patch with a `soundfile`-backed save fallback to the pinned Demucs checkout, and then runs `python3 -m demucs -d cpu test.mp3` once to verify the pinned stack, warm the default model, and confirm CPU inference still works on the checked out Demucs source revision.

## License
This repository is released under the MIT license as found in the [LICENSE](LICENSE) file.
