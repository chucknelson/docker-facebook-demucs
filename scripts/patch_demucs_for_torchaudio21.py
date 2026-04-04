from pathlib import Path


REPLACEMENTS = {
    Path("/lib/demucs/demucs/audio.py"): [
        (
            """import torchaudio as ta
import typing as tp
""",
            """import torchaudio as ta
import soundfile as sf
import typing as tp
""",
        ),
        (
            """    elif suffix == \".wav\":
        if as_float:
            bits_per_sample = 32
            encoding = 'PCM_F'
        else:
            encoding = 'PCM_S'
        ta.save(str(path), wav, sample_rate=samplerate,
                encoding=encoding, bits_per_sample=bits_per_sample)
    elif suffix == \".flac\":
        ta.save(str(path), wav, sample_rate=samplerate, bits_per_sample=bits_per_sample)
""",
            """    elif suffix in [\".wav\", \".flac\"]:
        subtype = None
        if suffix == \".wav\":
            if as_float:
                bits_per_sample = 32
                subtype = 'FLOAT'
            else:
                subtype = {
                    16: 'PCM_16',
                    24: 'PCM_24',
                    32: 'PCM_32',
                }[bits_per_sample]
        elif bits_per_sample in (16, 24):
            subtype = {
                16: 'PCM_16',
                24: 'PCM_24',
            }[bits_per_sample]
        try:
            if suffix == \".wav\":
                if as_float:
                    ta.save(str(path), wav, sample_rate=samplerate)
                else:
                    ta.save(str(path), wav, sample_rate=samplerate,
                            encoding='PCM_S', bits_per_sample=bits_per_sample)
            else:
                ta.save(str(path), wav, sample_rate=samplerate,
                        bits_per_sample=bits_per_sample)
        except (RuntimeError, TypeError) as error:
            if isinstance(error, TypeError) and 'encoding' not in str(error) and 'bits_per_sample' not in str(error):
                raise
            if isinstance(error, RuntimeError) and 'No audio I/O backend is available' not in str(error):
                raise
            sf.write(str(path), wav.transpose(0, 1).cpu().numpy(), samplerate,
                     subtype=subtype)
""",
        ),
    ],
    Path("/lib/demucs/demucs/wav.py"): [
        (
            """import torchaudio as ta
""",
            """import torchaudio as ta
import soundfile as sf
""",
        ),
        (
            """            if would_clip:
                assert ta.get_audio_backend() == 'soundfile', 'use dset.backend=soundfile'
            ta.save(file, audio, sr, encoding='PCM_F')
""",
            """            sf.write(str(file), audio.transpose(0, 1).cpu().numpy(), sr,
                     subtype='FLOAT')
""",
        ),
    ],
}


def main() -> None:
    for path, replacements in REPLACEMENTS.items():
        content = path.read_text()
        for old, new in replacements:
            if old not in content:
                raise SystemExit(f"Expected patch target not found in {path}")
            content = content.replace(old, new, 1)
        path.write_text(content)


if __name__ == "__main__":
    main()