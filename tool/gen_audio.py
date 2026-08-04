"""Generate the game's two sounds. Run: python tool/gen_audio.py

Synthesised rather than sourced, so they are tunable, licence-free and
regenerable. The numbers below ARE the sound design — change them here, not by
hunting for a replacement file.

drone.wav must loop seamlessly, which constrains it: every partial's frequency
times the loop length must be a whole number of cycles, or the wrap clicks.
4.0s was chosen because it makes 110/165/0.25 Hz all land on integers.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(abs(s) for s in samples) or 1.0
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, s / peak * 0.89)) * 32767))
        for s in samples
    )
    with wave.open(str(OUT / name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f"{name}: {len(samples)/RATE:.2f}s, {len(frames)/1024:.0f} KB")


def drone():
    """The room's tone. Held under everything, gain driven by proximity.

    A2 plus its fifth, deliberately bare — a triad would imply a resolution the
    player has not earned yet. The solve chord is where the third arrives.
    """
    n = int(RATE * 4.0)
    out = []
    for i in range(n):
        t = i / RATE
        # 1 full LFO cycle across the loop, so the wrap is silent.
        breathe = 1.0 + 0.14 * math.sin(2 * math.pi * 0.25 * t)
        s = (
            1.00 * math.sin(2 * math.pi * 110.0 * t)   # A2 root
            + 0.45 * math.sin(2 * math.pi * 165.0 * t)  # E3, the fifth
            + 0.16 * math.sin(2 * math.pi * 220.0 * t)  # octave, air
        )
        out.append(s * breathe)
    return out


def solve():
    """620ms, matched to the glow easing in main.dart so light and sound land
    together. The third finally appears: this is the only consonance in the
    game, and it should read as an arrival."""
    n = int(RATE * 0.62)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.sin(math.pi * min(1.0, t / 0.62)) ** 0.6  # soft in, long out
        strike = math.exp(-t * 26.0) * 0.35                  # a little edge
        s = (
            1.00 * math.sin(2 * math.pi * 220.0 * t)
            + 0.62 * math.sin(2 * math.pi * 277.18 * t)  # major third
            + 0.70 * math.sin(2 * math.pi * 330.0 * t)   # fifth
            + 0.30 * math.sin(2 * math.pi * 440.0 * t)
        )
        out.append(s * env + strike * math.sin(2 * math.pi * 880.0 * t))
    return out


if __name__ == "__main__":
    write("drone.wav", drone())
    write("solve.wav", solve())
