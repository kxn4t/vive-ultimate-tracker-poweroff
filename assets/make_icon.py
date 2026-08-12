"""Generate the app icon: a VIVE Ultimate Tracker with a power symbol.

A dark pebble-shaped tracker body with corner camera lenses, and a cyan
power symbol where the VIVE logo sits on the real device. Renders at high
resolution with supersampling, then downsamples to each ico size for crisp
edges. Outputs icon.ico (embedded into the exe by Ahk2Exe) and icon.png
(256px, for Stream Deck buttons etc.).

Requires Pillow:  pip install Pillow
"""
import os

from PIL import Image, ImageDraw, ImageFilter

SS = 8  # supersampling factor
BASE = 256
S = BASE * SS

BG_TOP = (30, 36, 48)        # background: dark slate
BG_BOTTOM = (18, 22, 30)
BODY_TOP = (62, 70, 84)      # tracker body: charcoal
BODY_BOTTOM = (38, 44, 56)
FACE = (50, 57, 70)          # face plate, slightly lighter than body edge
LENS = (96, 106, 122)
ACCENT = (0, 199, 224)       # VIVE-ish cyan
WHITE = (240, 248, 252)

HERE = os.path.dirname(os.path.abspath(__file__))


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    grad = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(grad)
    for y in range(size[1]):
        draw.line([(0, y), (size[0], y)],
                  fill=lerp(top, bottom, y / size[1]) + (255,))
    return grad


def make_base():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # rounded-square background
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=255)
    img.paste(vertical_gradient((S, S), BG_TOP, BG_BOTTOM), (0, 0), mask)

    # --- tracker body: wide rounded pebble ---
    bw, bh = S * 0.78, S * 0.60
    bx0, by0 = (S - bw) / 2, (S - bh) / 2
    bx1, by1 = bx0 + bw, by0 + bh
    body_radius = bh * 0.42

    body_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(body_mask).rounded_rectangle(
        [bx0, by0, bx1, by1], radius=body_radius, fill=255)
    img.paste(vertical_gradient((S, S), BODY_TOP, BODY_BOTTOM), (0, 0),
              body_mask)

    draw = ImageDraw.Draw(img)

    # face plate: inset rounded shape, slightly lighter
    inset = S * 0.035
    draw.rounded_rectangle(
        [bx0 + inset, by0 + inset, bx1 - inset, by1 - inset],
        radius=body_radius - inset * 0.8, fill=FACE + (255,))

    # --- camera lenses at the left and right edges, vertically centered ---
    lens_r = S * 0.042
    lens_cy = by0 + bh / 2
    for lx in (bx0 + bw * 0.115, bx1 - bw * 0.115):
        draw.ellipse([lx - lens_r, lens_cy - lens_r,
                      lx + lens_r, lens_cy + lens_r],
                     fill=LENS + (255,))

    # --- power symbol where the VIVE logo sits ---
    cx, cy = S / 2, by0 + bh * 0.57
    r = S * 0.135
    stroke = int(S * 0.045)

    # subtle glow behind the glyph (blurred so it fades out smoothly)
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    glow_r = r * 1.5
    ImageDraw.Draw(glow).ellipse(
        [cx - glow_r, cy - glow_r, cx + glow_r, cy + glow_r],
        fill=ACCENT + (60,))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.05))
    img.alpha_composite(glow)

    draw = ImageDraw.Draw(img)
    bbox = [cx - r, cy - r, cx + r, cy + r]
    draw.arc(bbox, start=-58, end=238, fill=ACCENT + (255,), width=stroke)
    # vertical bar with rounded ends
    bar_top = cy - r * 1.30
    bar_bottom = cy - r * 0.16
    draw.rounded_rectangle(
        [cx - stroke / 2, bar_top, cx + stroke / 2, bar_bottom],
        radius=stroke / 2, fill=WHITE + (255,))

    # diagonal "off" slash across the glyph, with a face-colored casing
    # so it reads as a separate stroke over the power symbol
    L = r * 1.45
    x0, y0 = cx - L * 0.707, cy + L * 0.707
    x1, y1 = cx + L * 0.707, cy - L * 0.707
    casing = stroke * 2.0
    draw.line([x0, y0, x1, y1], fill=FACE + (255,), width=int(casing))
    for ex, ey in ((x0, y0), (x1, y1)):
        draw.ellipse([ex - casing / 2, ey - casing / 2,
                      ex + casing / 2, ey + casing / 2], fill=FACE + (255,))
    draw.line([x0, y0, x1, y1], fill=WHITE + (255,), width=stroke)
    for ex, ey in ((x0, y0), (x1, y1)):
        draw.ellipse([ex - stroke / 2, ey - stroke / 2,
                      ex + stroke / 2, ey + stroke / 2], fill=WHITE + (255,))

    return img


base = make_base()
sizes = [16, 24, 32, 48, 64, 128, 256]
imgs = [base.resize((s, s), Image.LANCZOS) for s in sizes]

imgs[-1].save(os.path.join(HERE, "icon.ico"), format="ICO",
              append_images=imgs[:-1], sizes=[(s, s) for s in sizes])
base.resize((BASE, BASE), Image.LANCZOS).save(os.path.join(HERE, "icon.png"))
print("done")
