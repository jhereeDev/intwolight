"""Push press/icon-1024.png into every app icon slot, iOS and Android.

Run: python press/apply_icon.py

Resizes into whatever slots already exist rather than inventing a manifest —
the .appiconset and the mipmap folders are the source of truth for which sizes
Xcode and Gradle expect, and regenerating that list by hand is how a slot goes
missing and an icon silently falls back to the Flutter default.

⚠️ iOS icons must be **opaque**. App Store Connect rejects any alpha channel in
the 1024 marketing icon, so every write is forced to RGB.

Android adaptive icons (`ic_launcher_foreground`) are a different shape problem
— they get masked to a circle/squircle and the outer ~18% is trimmed, so the
full mark cannot be used as-is. The foreground is generated from a centre crop
with the mark scaled to survive the mask.
"""
import glob
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "press", "icon-1024.png")

IOS = os.path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
MIPMAP = os.path.join(ROOT, "android/app/src/main/res")

# Legacy square launcher icons.
MIPMAP_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Adaptive foreground. 108dp canvas, but only the middle 72dp is guaranteed
# visible — anything outside is mask, so the mark is inset to survive it.
FOREGROUND_SIZES = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432,
}
SAFE = 72 / 108


def main():
    if not os.path.exists(SRC):
        sys.exit(f"missing {SRC} — run press/make_icon.py first")
    src = Image.open(SRC).convert("RGB")
    n = 0

    for path in sorted(glob.glob(os.path.join(IOS, "*.png"))):
        size = Image.open(path).size
        src.resize(size, Image.LANCZOS).save(path, "PNG")
        n += 1
    print(f"iOS: {n} slots")

    for folder, size in MIPMAP_SIZES.items():
        path = os.path.join(MIPMAP, folder, "ic_launcher.png")
        if not os.path.exists(path):
            continue
        src.resize((size, size), Image.LANCZOS).save(path, "PNG")
        n += 1

    for folder, size in FOREGROUND_SIZES.items():
        path = os.path.join(MIPMAP, folder, "ic_launcher_foreground.png")
        if not os.path.exists(path):
            continue
        inner = int(size * SAFE)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        canvas.paste(src.resize((inner, inner), Image.LANCZOS),
                     ((size - inner) // 2, (size - inner) // 2))
        canvas.save(path, "PNG")
        n += 1

    # Proof sheet for the press kit. Regenerated here rather than by hand so it
    # can never show the previous icon next to the current app.
    sizes = [180, 120, 87, 60, 40, 29]
    pad, gap = 24, 22
    sheet = Image.new("RGB", (1024, max(sizes) + pad * 2), (10, 10, 12))
    x = pad
    for sz in sizes:
        sheet.paste(src.resize((sz, sz), Image.LANCZOS),
                    (x, pad + (max(sizes) - sz) // 2))
        x += sz + gap
    sheet.save(os.path.join(ROOT, "press", "icon-sizes.png"), "PNG")

    print(f"wrote {n} icon files + proof sheet from {os.path.relpath(SRC, ROOT)}")


if __name__ == "__main__":
    main()
