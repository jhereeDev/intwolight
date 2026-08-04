"""Devpost thumbnail for In Two Lights — 3:2, dark, two light sources.

Run: python press/make_thumb.py press/raw2/01-silhouette.png press/devpost-thumbnail.png

⚠️ Feed it a RAW device capture, not a press/devpost/ one — those are padded to
a fixed store aspect, and padding inside a panel that is itself a crop reads as
a mistake.

The shot is cropped to the room and its HUD rather than shown as a whole phone.
A Devpost thumbnail is browsed at a few hundred pixels wide; the app's lower
third is deliberately empty, and at that size empty space is indistinguishable
from a broken image. Cropped, the corner fills the panel.
"""
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1500, 1000                      # 3:2
BG = (10, 10, 12)
AMBER = (224, 168, 46)
TEXT = (238, 238, 240)
MUTED = (140, 140, 148)

F = "C:/Windows/Fonts/"
title_f = ImageFont.truetype(F + "segoeuil.ttf", 82)
tag_f = ImageFont.truetype(F + "segoeuil.ttf", 34)
small_f = ImageFont.truetype(F + "segoeui.ttf", 22)
kick_f = ImageFont.truetype(F + "segoeuisl.ttf", 20)
stat_f = ImageFont.truetype(F + "segoeuisl.ttf", 21)

img = Image.new("RGB", (W, H), BG)

# --- two light sources, the literal premise of the game ---------------------
# Warm on the left, cool on the right — matching the per-chapter Ambience the
# game actually renders, rather than two arbitrary yellows.
glow = Image.new("RGB", (W, H), BG)
gd = ImageDraw.Draw(glow)
for cx, cy, rad, col in ((210, 40, 620, (92, 71, 34)), (1230, -40, 700, (44, 58, 78))):
    for i in range(rad, 0, -8):
        t = 1 - i / rad
        gd.ellipse([cx - i, cy - i, cx + i, cy + i],
                   fill=tuple(int(BG[k] + (col[k] - BG[k]) * t * t) for k in range(3)))
img = Image.blend(img, glow.filter(ImageFilter.GaussianBlur(60)), 0.9)
d = ImageDraw.Draw(img)


def tracked(draw, xy, text, font, fill, track=0):
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=font, fill=fill)
        x += draw.textlength(ch, font=font) + track
    return x


# --- left column -----------------------------------------------------------
X = 96
tracked(d, (X, 300), "SHIPATON 2026", kick_f, AMBER, track=3.2)
tracked(d, (X, 348), "IN TWO LIGHTS", title_f, TEXT, track=5)

d.line([(X, 470), (X + 96, 470)], fill=AMBER, width=3)

for i, line in enumerate([
        "One sculpture. Two shadows.",
        "Both must land at once —",
        "and fixing one breaks the other.",
]):
    d.text((X, 512 + i * 46), line, font=tag_f, fill=(196, 196, 202))

tracked(d, (X, 684), "47 ROOMS  ·  5 CHAPTERS  ·  ENDLESS", stat_f, AMBER, track=1.6)
d.text((X, 728), "A wordless spatial-deduction puzzle.", font=small_f, fill=MUTED)
d.text((X, 760), "No words. No timer. No hints.", font=small_f, fill=MUTED)

# --- right: the actual game ------------------------------------------------
# 130px of Android status bar off the top; the bottom is cropped to just under
# the room so the corner, not the empty floor, is what fills the panel.
shot = Image.open(sys.argv[1]).convert("RGB")
shot = shot.crop((0, 130, shot.width, int(shot.height * 0.71)))
th = 840
tw = int(shot.width * th / shot.height)
shot = shot.resize((tw, th), Image.LANCZOS)

px, py = W - tw - 80, (H - th) // 2
d.rounded_rectangle([px - 14, py - 14, px + tw + 14, py + th + 14],
                    radius=16, fill=(20, 20, 23))
img.paste(shot, (px, py))
d.rounded_rectangle([px - 1, py - 1, px + tw, py + th], radius=4, outline=(58, 58, 64), width=2)

img.save(sys.argv[2], quality=95)
print(f"wrote {sys.argv[2]}  {W}x{H}  ratio {W/H:.3f}  panel {tw}x{th} at x={px}")
