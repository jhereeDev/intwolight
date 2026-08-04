"""App icon for In Two Lights — 1024x1024, opaque (the App Store rejects alpha).

Run:  python press/make_icon.py
Then: dart run flutter_launcher_icons

Writes BOTH press/icon-1024.png (the press kit copy) and assets/icon.png,
which is what `flutter_launcher_icons` reads — it is configured in pubspec.yaml
and owns every slot in the app. Do not hand-resize icons into ios/ or android/;
that tool already does it, and a hand-rolled resizer will drift from whatever
sizes Xcode and Gradle actually expect.

The mark states the mechanic and nothing else: **one object, two different
shadows.** A circle on the left wall, a triangle on the right. Same sculpture,
two irreconcilable readings — which is the entire game, and is a claim no other
shadow puzzler's icon makes.

Replaces a busier mark (hexagon outline + two glows + two blobs + a seam). Five
elements competing at 40px is a texture, not a symbol. This is four flat tones
and two primitives.

Why a circle and a triangle rather than two organic shapes: primitives are
unmistakable at any size, and their *difference* is instant. Two blobs read as
"two blobs"; a circle and a triangle read as "these cannot be the same thing" —
which is precisely the tension the game runs on.
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 1024
SEAM = S / 2

# Two walls in one room, lit differently. The split is what makes a flat
# square read as a folded corner — without it this is a poster, not a room.
# Bright enough that a near-black shadow actually reads. The first pass used
# the game's in-scene wall values and produced a black square at 40px — a lit
# wall in a 1024px icon has to be far lighter than a lit wall on a phone
# screen, because the icon has no surrounding darkness to be relative to.
# Two lights of different COLOUR TEMPERATURE, not just brightness. Warm on the
# left, cool on the right. It costs nothing, and it makes the icon say "two
# separate lights" rather than "one light and a shaded side" — which is the
# difference between this game and every other shadow puzzler.
WALL_L = (118, 103, 84)
WALL_R = (68, 68, 84)
SHADOW = (9, 8, 11)
AMBER = (224, 168, 46)


def wall_panel(width, height, top, bottom):
    """A panel with a soft vertical falloff, so light reads as coming from
    above rather than the wall being a swatch."""
    panel = Image.new("RGB", (1, height))
    px = panel.load()
    for y in range(height):
        t = (y / (height - 1)) ** 0.75
        px[0, y] = tuple(int(a + (b - a) * t) for a, b in zip(top, bottom))
    return panel.resize((width, height), Image.BILINEAR)


def main():
    img = Image.new("RGB", (S, S), WALL_R)

    # The corner: two panels, brighter on the left, meeting at the seam.
    img.paste(wall_panel(int(SEAM), S, WALL_L, (48, 42, 38)), (0, 0))
    img.paste(wall_panel(S - int(SEAM), S, WALL_R, (27, 27, 36)), (int(SEAM), 0))

    # A single warm wash spilling down the fold. The only colour in the mark,
    # and the only thing that says "light" rather than "diagram".
    wash = Image.new("RGB", (S, S), (0, 0, 0))
    wd = ImageDraw.Draw(wash)
    for i in range(40, 0, -1):
        t = i / 40
        r = S * 0.62 * t
        wd.ellipse([SEAM - r, -S * 0.30 - r, SEAM + r, -S * 0.30 + r],
                   fill=tuple(int(c * (1 - t) ** 1.6 * 0.55) for c in AMBER))
    img = ImageChops.screen(img, wash.filter(ImageFilter.GaussianBlur(S * 0.06)))

    # The two shadows. Drawn into a mask first so both get the same softness —
    # a shadow with a hard edge reads as a sticker.
    shadows = Image.new("L", (S, S), 0)
    sd = ImageDraw.Draw(shadows)

    # Slightly above centre: the first pass sat them low and left dead space
    # under the mark, which reads as a cropping mistake at small sizes.
    cy = S * 0.52
    rad = S * 0.158
    sd.ellipse([SEAM * 0.5 - rad, cy - rad, SEAM * 0.5 + rad, cy + rad], fill=255)

    tx, tr = SEAM + (S - SEAM) * 0.5, S * 0.185
    sd.polygon(
        [(tx + math.cos(math.radians(a)) * tr, cy + math.sin(math.radians(a)) * tr)
         for a in (-90, 30, 150)],
        fill=255,
    )

    shadows = shadows.filter(ImageFilter.GaussianBlur(S * 0.006))
    img.paste(Image.new("RGB", (S, S), SHADOW), (0, 0), shadows)

    # The seam last, so nothing crosses it. Hairline: it is the fold, not a
    # border, and a thick line would cut the icon in half.
    ImageDraw.Draw(img).line(
        [(SEAM, 0), (SEAM, S)], fill=(20, 18, 20), width=max(1, int(S * 0.004))
    )

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for out in (os.path.join(root, "press", "icon-1024.png"),
                os.path.join(root, "assets", "icon.png")):
        img.save(out, "PNG")
        print(f"wrote {os.path.relpath(out, root)}  {S}x{S}  mode={img.mode}")
    # Proof sheet for the press kit, regenerated here so it can never end up
    # advertising the previous icon next to the current app.
    sizes = [180, 120, 87, 60, 40, 29]
    pad, gap = 24, 22
    sheet = Image.new("RGB", (1024, max(sizes) + pad * 2), (10, 10, 12))
    x = pad
    for sz in sizes:
        sheet.paste(img.resize((sz, sz), Image.LANCZOS),
                    (x, pad + (max(sizes) - sz) // 2))
        x += sz + gap
    sheet.save(os.path.join(root, "press", "icon-sizes.png"), "PNG")

    print("now run: dart run flutter_launcher_icons")


if __name__ == "__main__":
    main()
