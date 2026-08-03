"""App icon for In Two Lights — 1024x1024, no alpha (App Store requires opaque).

The mark is the game screen reduced to its irreducible parts: the hexagon the
isometric corner projects to, the seam where the two walls meet, a light on
each wall, and a dark shape on each wall. Nothing else survives at 40px.

Two things learned making this:
  * glows must be composited INSIDE the hexagon and masked to it — drawn
    behind, all you see is the bleed around the edge;
  * they must be screened, not blended. Image.blend averages, so the second
    glow erases the first and the icon quietly stops being about two lights.
"""
import math
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

S = 1024
BG = (7, 7, 9)
WALL = (26, 23, 27)
AMBER = (224, 168, 46)
WARM = (255, 214, 140)


def hexagon(cx, cy, r):
    return [
        (cx + math.cos(math.pi / 2 + i * math.pi / 3) * r,
         cy - math.sin(math.pi / 2 + i * math.pi / 3) * r)
        for i in range(6)
    ]


def glow(centre, radius, colour, peak):
    layer = Image.new("RGB", (S, S), (0, 0, 0))
    d = ImageDraw.Draw(layer)
    steps = 48
    for i in range(steps, 0, -1):
        t = i / steps
        r = radius * t
        a = (1 - t) ** 1.7 * peak
        d.ellipse([centre[0] - r, centre[1] - r, centre[0] + r, centre[1] + r],
                  fill=tuple(int(c * a) for c in colour))
    return layer.filter(ImageFilter.GaussianBlur(S * 0.05))


def main(out):
    cx, cy, r = S / 2, S * 0.50, S * 0.335
    pts = hexagon(cx, cy, r)

    img = Image.new("RGB", (S, S), BG)
    ImageDraw.Draw(img).polygon(pts, fill=WALL)

    # Two lights, one per wall, screened together so both survive, then
    # masked to the room so the light stays inside the room.
    lights = ImageChops.screen(
        glow((cx - r * 0.42, cy - r * 0.20), r * 0.95, WARM, 0.60),
        glow((cx + r * 0.42, cy - r * 0.20), r * 0.95, WARM, 0.52),
    )
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    img.paste(ImageChops.screen(img, lights), (0, 0), mask)

    d = ImageDraw.Draw(img)

    # A dark shape on each wall — different shapes, because the whole game is
    # that one form reads two ways.
    shadows = Image.new("L", (S, S), 0)
    sd = ImageDraw.Draw(shadows)
    sd.polygon([(cx - r * 0.60, cy - r * 0.16), (cx - r * 0.22, cy - r * 0.30),
                (cx - r * 0.16, cy + r * 0.20), (cx - r * 0.54, cy + r * 0.34)],
               fill=255)
    sd.polygon([(cx + r * 0.24, cy - r * 0.34), (cx + r * 0.58, cy - r * 0.22),
                (cx + r * 0.50, cy + r * 0.30), (cx + r * 0.30, cy + r * 0.12)],
               fill=255)
    shadows = shadows.filter(ImageFilter.GaussianBlur(S * 0.008))
    shadows = ImageChops.multiply(shadows, mask)  # never spill past the walls
    img.paste(Image.new("RGB", (S, S), (5, 5, 7)), (0, 0), shadows)

    # The seam, then the room outline last so nothing overlaps it.
    d.line([(cx, cy - r * 0.90), (cx, cy + r * 0.12)],
           fill=(226, 208, 178), width=int(S * 0.013))
    d.line(pts + [pts[0]], fill=AMBER, width=int(S * 0.030), joint="curve")

    img.save(out, "PNG")
    print(f"wrote {out}  {S}x{S}  mode={img.mode}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "icon.png")
