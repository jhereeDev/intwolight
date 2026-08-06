"""Turn raw device captures into the two sizes the stores require.

Run: python press/make_shots.py press/raw/*.png

  App Store 6.9"  1320x2868  -> press/store/
  Devpost         1179x2556  -> press/devpost/

**Contain and pad, never crop.** The emulator is 1280x2856 (aspect 0.4482) and
the iPhone target is 0.4603, so covering the frame would shave ~77px off the
height — which is exactly where the level counter and the two meters live. The
padding is the app's own background, so on a dark UI the seam is invisible.
Losing the HUD to a crop is not.
"""
import glob
import os
import sys

from PIL import Image

BG = (8, 8, 10)  # scaffoldBackgroundColor
TARGETS = {
    "store": (1320, 2868),     # App Store, 6.9" iPhone
    "store65": (1242, 2688),   # App Store, 6.5" iPhone — the slot the 1.0
                               # submission form actually presents
    "devpost": (1179, 2556),   # Devpost gallery
}
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# The captures come from an ANDROID emulator, so the top carries Android's
# status bar (clock, wifi, battery) and the bottom its gesture pill. Shipping
# those in an iOS App Store listing advertises the wrong platform on every
# screenshot. Cropped away before fitting; the game draws nothing there.
#
# ⚠️ PROPORTIONAL, not absolute. These were 130 and 110 pixels, measured on the
# 1280x2856 emulator this file was written against. `Medium_Phone_API_36.0`
# captures at 1080x2400, where a fixed 130px eats 5.4% of the frame instead of
# 4.6% — enough to clip the close button off the top of the unlock screen. The
# chrome is a fraction of the display, so the crop has to be one too.
CROP_TOP_FRAC, CROP_BOTTOM_FRAC = 130 / 2856, 110 / 2856


def strip_chrome(im):
    top = round(im.height * CROP_TOP_FRAC)
    bottom = round(im.height * CROP_BOTTOM_FRAC)
    return im.crop((0, top, im.width, im.height - bottom))


def fit(im, size):
    tw, th = size
    scale = min(tw / im.width, th / im.height)
    w, h = max(1, round(im.width * scale)), max(1, round(im.height * scale))
    canvas = Image.new("RGB", size, BG)
    canvas.paste(im.resize((w, h), Image.LANCZOS), ((tw - w) // 2, (th - h) // 2))
    return canvas


def main(paths):
    if not paths:
        sys.exit("usage: make_shots.py <raw captures...>")
    for folder in TARGETS:
        os.makedirs(os.path.join(ROOT, "press", folder), exist_ok=True)

    for path in sorted(paths):
        src = strip_chrome(Image.open(path).convert("RGB"))
        name = os.path.basename(path)
        for folder, size in TARGETS.items():
            out = os.path.join(ROOT, "press", folder, name)
            fit(src, size).save(out, "PNG")
        print(f"{name}: {src.width}x{src.height} -> "
              + ", ".join(f"{w}x{h}" for w, h in TARGETS.values()))


if __name__ == "__main__":
    args = sys.argv[1:]
    expanded = []
    for a in args:
        expanded.extend(glob.glob(a) or [a])
    main(expanded)
