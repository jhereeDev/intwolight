"""13-inch iPad screenshots — 2064x2752.

Run:  python press/make_ipad_shots.py press/raw-ipad/*.png  ->  press/ipad13/

**App Store Connect will not let you Add for Review without these** if the app
targets iPad, which this one does (TARGETED_DEVICE_FAMILY includes iPad, and
Info.plist carries UIRequiresFullScreen). The error is a flat "You must upload
a screenshot for 13-inch iPad displays" on the version page.

⚠️ **Do not pillarbox the phone captures into an iPad frame.** The phone raws
are 1080x2400 (aspect 0.45) and the iPad target is 0.75, so containing one
leaves enormous bars and — worse — the HUD stays phone-sized and edge-anchored
in the wrong place. It advertises an iPad experience the app does not have.

Capture at real iPad geometry instead. The Android emulator can be told to be
an iPad:

    adb shell wm size 2064x2752
    adb shell wm density 320          # -> 1032x1376 logical, iPad 13" is 1024x1366
    # launch the SHOT harness, tap through, screencap each shot
    adb shell wm size reset && adb shell wm density reset

That renders the real layout at the real aspect — `fitScene` re-fits the room,
and the HUD anchors where it actually would. The captures come out already at
2064x2752; this script only strips Android's chrome and refits.
"""
import glob
import os
import sys

from PIL import Image

BG = (8, 8, 10)  # scaffoldBackgroundColor
SIZE = (2064, 2752)  # 13-inch iPad, portrait
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Same proportions as make_shots.py — see the note there about why these are
# fractions rather than the pixel counts they started as.
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
        sys.exit("usage: make_ipad_shots.py <raw iPad captures...>")
    out_dir = os.path.join(ROOT, "press", "ipad13")
    os.makedirs(out_dir, exist_ok=True)
    for path in sorted(paths):
        src = strip_chrome(Image.open(path).convert("RGB"))
        name = os.path.basename(path)
        fit(src, SIZE).save(os.path.join(out_dir, name), "PNG")
        print(f"{name}: {src.width}x{src.height} -> {SIZE[0]}x{SIZE[1]}")


if __name__ == "__main__":
    args = sys.argv[1:]
    expanded = []
    for a in args:
        expanded.extend(glob.glob(a) or [a])
    main(expanded)
