"""Devpost thumbnail for In Two Lights — 3:2, dark, two light sources."""
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1500, 1000                      # 3:2
BG = (10, 10, 12)
AMBER = (224, 168, 46)
WARM = (255, 214, 140)
TEXT = (238, 238, 240)
MUTED = (140, 140, 148)

F = "C:/Windows/Fonts/"
title_f = ImageFont.truetype(F + "segoeuil.ttf", 96)
tag_f = ImageFont.truetype(F + "segoeuil.ttf", 34)
small_f = ImageFont.truetype(F + "segoeui.ttf", 22)
kick_f = ImageFont.truetype(F + "segoeuisl.ttf", 20)

img = Image.new("RGB", (W, H), BG)

# --- two light sources, the literal premise of the game ---------------------
glow = Image.new("RGB", (W, H), BG)
gd = ImageDraw.Draw(glow)
for cx, cy, rad, col in ((210, 40, 620, (92, 71, 34)), (1230, -40, 700, (74, 60, 38))):
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

d.line([(X, 486), (X + 96, 486)], fill=AMBER, width=3)

for i, line in enumerate([
        "Two lights. One form. Two shadows",
        "that must both be true at once —",
        "and fixing one always breaks the other.",
]):
    d.text((X, 528 + i * 46), line, font=tag_f, fill=(196, 196, 202))

d.text((X, 700), "A wordless spatial-deduction puzzle.", font=small_f, fill=MUTED)
d.text((X, 732), "No words. No timer. No hints.", font=small_f, fill=MUTED)

# --- right: the actual game ------------------------------------------------
shot = Image.open(sys.argv[1]).convert("RGB")
shot = shot.crop((0, int(shot.height * 0.035), shot.width, shot.height))  # drop status bar
th = 860
tw = int(shot.width * th / shot.height)
shot = shot.resize((tw, th), Image.LANCZOS)

px, py = W - tw - 130, (H - th) // 2
d.rounded_rectangle([px - 14, py - 14, px + tw + 14, py + th + 14],
                    radius=26, fill=(20, 20, 23))
img.paste(shot, (px, py))
d.rounded_rectangle([px - 1, py - 1, px + tw, py + th], radius=6, outline=(58, 58, 64), width=2)

img.save(sys.argv[2], quality=95)
print(f"wrote {sys.argv[2]}  {W}x{H}  ratio {W/H:.3f}")
