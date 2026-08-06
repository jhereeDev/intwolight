"""Promotional image for the In Two Lights Pro in-app purchase.

Run:  python press/make_promo.py   ->  press/iap-promo-1024.png

This is NOT the review screenshot. App Store Connect's in-app purchase page has
two image fields with different rules, and putting the right file in the wrong
one is rejected on dimensions:

  Review Information -> Screenshot   press/store/07-unlock.png (1320x2868)
                                     The REQUIRED one. Shows the reviewer the
                                     purchase actually on offer. Captured by
                                     Shot('07-unlock') and sized by
                                     make_shots.py -- Apple requires it to match
                                     one of the App Store screenshot specs the
                                     app supports, so a raw 1080x2400 grab is
                                     rejected exactly like a wrong-size promo.

  Image (Optional)                   this file. STRICTLY 1024x1024, 72 dpi,
                                     RGB, flattened, no rounded corners, no
                                     alpha. Appears when a customer redeems an
                                     offer code — which matters here, because
                                     Shipaton requires promo codes so judges
                                     can unlock the paid content.

A phone screenshot can never satisfy the second: it is portrait, and cropping
one to square either loses the headline or loses the art.

The mark follows the icon's rule — flat tones and primitives, no texture. The
game's own paywall already has the right image in it: a lit hexagon leading a
chain of dark ones, because a map node IS a hexagon and a chapter IS a chain of
them. Here that chain becomes a field: one room lit, the rest waiting. That is
literally what is being sold.
"""
import math

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 1024
BG = (8, 8, 10)            # scaffoldBackgroundColor
AMBER = (224, 168, 46)     # _amber
DIM = (150, 150, 158)
F = "C:/Windows/Fonts/"


def hexagon(cx, cy, r):
    """Flat-top hexagon, matching the map node and the paywall's chain."""
    return [
        (cx + r * math.cos(math.pi / 6 + v * math.pi / 3),
         cy + r * math.sin(math.pi / 6 + v * math.pi / 3))
        for v in range(6)
    ]


img = Image.new("RGB", (S, S), BG)
d = ImageDraw.Draw(img)

# A honeycomb, centred. Odd row counts so there is a true middle cell to light.
R = 96
DX = R * math.sqrt(3)
DY = R * 1.5
ROWS = [3, 4, 5, 4, 3]
cy0 = S / 2 - (len(ROWS) - 1) * DY / 2

cells = []
for row, n in enumerate(ROWS):
    cy = cy0 + row * DY
    cx0 = S / 2 - (n - 1) * DX / 2
    for i in range(n):
        cells.append((cx0 + i * DX, cy, row, i))

# The lit one is the middle of the middle row: the free chapter you already
# have. Everything around it is what the purchase turns on.
lit = (S / 2, cy0 + 2 * DY)

glow = Image.new("RGB", (S, S), BG)
gd = ImageDraw.Draw(glow)
gd.polygon(hexagon(*lit, R * 0.94), fill=(120, 90, 26))
glow = glow.filter(ImageFilter.GaussianBlur(64))
img = Image.blend(img, glow, 0.55)
d = ImageDraw.Draw(img)

for cx, cy, row, i in cells:
    is_lit = abs(cx - lit[0]) < 1 and abs(cy - lit[1]) < 1
    poly = hexagon(cx, cy, R * 0.9)
    if is_lit:
        d.polygon(poly, fill=(58, 42, 12), outline=AMBER, width=5)
        # The seam every room in the game has — two walls meeting. Without it
        # this is a honeycomb; with it, each cell is a corner.
        d.line([(cx, cy - R * 0.9), (cx, cy + R * 0.42)], fill=AMBER, width=4)
    else:
        # Falls off with distance, so the field reads as depth rather than as
        # a flat grid of identical cells.
        #
        # The floor is deliberately high. The first pass fell to 0.10 at the
        # edges, which looks right at 1024px and disappears entirely at the
        # ~250px an offer-code redemption actually renders — leaving one amber
        # hexagon alone on black, which says "one room" when the whole point is
        # "all of them".
        dist = math.hypot(cx - lit[0], cy - lit[1]) / (S * 0.42)
        a = max(0.26, 0.62 - dist * 0.34)
        edge = tuple(round(BG[k] + (DIM[k] - BG[k]) * a) for k in range(3))
        d.polygon(poly, outline=edge, width=3)
        d.line([(cx, cy - R * 0.9), (cx, cy + R * 0.42)],
               fill=edge, width=2)

# Wordmark. Letterspaced caps, the same treatment the paywall's kicker uses.
def tracked(draw, y, text, font, fill, track):
    w = sum(draw.textlength(c, font=font) + track for c in text) - track
    x = (S - w) / 2
    for c in text:
        draw.text((x, y), c, font=font, fill=fill)
        x += draw.textlength(c, font=font) + track


tracked(d, S - 132, "ALL CHAPTERS",
        ImageFont.truetype(F + "segoeuil.ttf", 62), (238, 238, 242), 10)
tracked(d, S - 56, "ONE PAYMENT",
        ImageFont.truetype(F + "segoeuisl.ttf", 24), AMBER, 9)

# Flattened RGB, no alpha, no rounded corners — all three are requirements.
img.convert("RGB").save("press/iap-promo-1024.png", dpi=(72, 72))
print("wrote press/iap-promo-1024.png", img.size, img.mode)
