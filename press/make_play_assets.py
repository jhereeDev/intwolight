"""Google Play store assets — the two sizes iOS never asked for.

Run:  python press/make_play_assets.py

  press/play/feature-graphic-1024x500.png   REQUIRED by Play, no iOS equivalent
  press/play/icon-512.png                   Play wants 512x512; iOS wanted 1024

The feature graphic is the banner at the top of the Play listing and in
promotional placements. It is **not** a screenshot slot — a cropped phone
capture reads as a mistake there, and Play's own guidance is that text should
be minimal because the graphic is often shown with the app title overlaid
elsewhere.

The mark is the icon's claim restated in landscape: **one object, two
different shadows.** Warm light from the left throws a circle; cool light from
the right throws a triangle. Same object, two irreconcilable readings — which
is the whole game, and is a claim no other shadow puzzler's banner makes.
Kept to flat tones and primitives for the same reason `make_icon.py` is: five
elements competing is a texture, not a symbol.
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

W, H = 1024, 500
BG = (8, 8, 10)          # scaffoldBackgroundColor
WARM = (255, 214, 140)   # _warm
COOL = (191, 210, 242)   # _cool
AMBER = (224, 168, 46)   # _amber
F = "C:/Windows/Fonts/"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "press", "play")


def glow(img, xy, r, colour):
    """A soft pool of light, added to whatever is already lit.

    ⚠️ **Additive, not `Image.blend`.** The first version blended each pool in
    turn at 0.94 strength, which meant the second call blended the
    already-warm image and kept ~6% of the first pool — the warm side simply
    vanished and no amount of brightening brought it back, because the problem
    was never brightness. Two lamps in a room add; they do not replace each
    other, which is the same reason the scene unions its shadows rather than
    painting them one over the next.
    """
    layer = Image.new("RGB", img.size, (0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([xy[0] - r, xy[1] - r, xy[0] + r, xy[1] + r], fill=colour)
    return ImageChops.add(img, layer.filter(ImageFilter.GaussianBlur(r * 0.34)))


img = Image.new("RGB", (W, H), BG)
# Two lamps of different colour TEMPERATURE, not just brightness. That contrast
# is how the two walls stay legible as two separate constraints.
#
# ⚠️ These are far brighter than the in-game wall values, on purpose. The game
# draws **shadows dark on lit walls**, so a wall that is nearly black has
# nothing for a shadow to be darker than — the first pass lost the circle
# entirely and the banner read as "a hexagon next to a triangle". Same lesson
# make_icon.py records for the 40px icon: a lit wall in a promo graphic has to
# be much lighter than a lit wall on a phone, because there is no surrounding
# darkness to be relative to.
img = glow(img, (238, 226), 250, (150, 118, 66))
img = glow(img, (786, 226), 250, (74, 92, 132))
d = ImageDraw.Draw(img)

CX, CY = W // 2, 226

# The two shadows, one per wall. Near-black, so they read against the pools.
SHADOW_W = (26, 21, 14)
SHADOW_C = (16, 19, 27)
d.ellipse([238 - 74, CY - 74, 238 + 74, CY + 74], fill=SHADOW_W)
d.polygon([(786 - 82, CY + 70), (786 + 82, CY + 70), (786, CY - 80)],
          fill=SHADOW_C)

# The object itself — a hexagon, the shape a map node already is.
hexa = [
    (CX + 62 * math.cos(math.pi / 6 + v * math.pi / 3),
     CY + 62 * math.sin(math.pi / 6 + v * math.pi / 3))
    for v in range(6)
]
d.polygon(hexa, fill=(58, 42, 12), outline=AMBER, width=4)
# The seam every room in the game has: two walls meeting.
d.line([(CX, CY - 62), (CX, CY + 30)], fill=AMBER, width=3)


def tracked(draw, y, text, font, fill, track):
    w = sum(draw.textlength(c, font=font) + track for c in text) - track
    x = (W - w) / 2
    for c in text:
        draw.text((x, y), c, font=font, fill=fill)
        x += draw.textlength(c, font=font) + track


tracked(d, 342, "IN TWO LIGHTS",
        ImageFont.truetype(F + "segoeuil.ttf", 62), (240, 240, 244), 12)
tracked(d, 422, "ONE SCULPTURE  ·  TWO SHADOWS  ·  ONE ANSWER",
        ImageFont.truetype(F + "segoeuisl.ttf", 19), AMBER, 5)

os.makedirs(OUT, exist_ok=True)
img.convert("RGB").save(os.path.join(OUT, "feature-graphic-1024x500.png"))
print("wrote feature-graphic-1024x500.png", img.size, img.mode)

# Play's icon slot is 512; the App Store's was 1024. Same artwork, downscaled
# through LANCZOS rather than redrawn, so the two stores cannot drift apart.
src = os.path.join(ROOT, "press", "icon-1024.png")
icon = Image.open(src).convert("RGB").resize((512, 512), Image.LANCZOS)
icon.save(os.path.join(OUT, "icon-512.png"))
print("wrote icon-512.png", icon.size, icon.mode)
