"""Render 1024x1024 promotional image for the Lifetime In-App Purchase.

Specs for App Store Promotion / Offer Codes:
- Dimensions: exactly 1024 x 1024 px.
- Format: PNG, RGB (no alpha / no transparency — Apple requires opaque).
- Composition: Brand seal with golden celestial moon + lotus + crown, balanced typography.
"""

from PIL import Image, ImageDraw, ImageFont

BG = (254, 249, 241)             # New Rice Ivory #FEF9F1 (RGB, no alpha)
IVORY = (254, 249, 241)
RED = (194, 59, 34)              # Imperial Vermilion #C23B22
RED_SHADOW = (225, 205, 185)     # Subtle warm shadow
GOLD = (197, 160, 89)            # Imperial Chrysanthemum Gold #C5A059
GOLD_LIGHT = (233, 203, 143)
FRAME = (230, 222, 200)
INK = (29, 28, 23)               # Deep Calligraphic Ink #1D1C17
ASH = (89, 65, 60)               # Hearth Ash

SIZE = 1024


def load_font(name, size):
    paths = {
        "NewYork": "/System/Library/Fonts/NewYork.ttf",
        "SFProText": "/System/Library/Fonts/SFProText-Regular.ttf",
        "SFProTextBold": "/System/Library/Fonts/SFProText-Bold.ttf",
    }
    try:
        return ImageFont.truetype(paths[name], size)
    except OSError:
        try:
            return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size)
        except OSError:
            return ImageFont.load_default()


def render_lifetime_promo(output_path):
    img = Image.new("RGB", (SIZE, SIZE), BG)
    draw = ImageDraw.Draw(img)

    # 1. Outer decorative traditional frame (nested rounded borders)
    pad = 48
    draw.rounded_rectangle(
        [pad, pad, SIZE - pad, SIZE - pad], radius=140, outline=FRAME, width=3
    )
    draw.rounded_rectangle(
        [pad + 10, pad + 10, SIZE - pad - 10, SIZE - pad - 10],
        radius=130,
        outline=GOLD,
        width=1,
    )

    # Corner ornaments (classical quadrant dots)
    corner_inset = pad + 32
    for cx_c in [corner_inset, SIZE - corner_inset]:
        for cy_c in [corner_inset, SIZE - corner_inset]:
            draw.ellipse([cx_c - 4, cy_c - 4, cx_c + 4, cy_c + 4], fill=GOLD)

    # 2. Main Center Seal (Ấn Triện)
    # Balanced size: 480x480, centered horizontally, positioned to leave room for text
    seal_w = 460
    seal_h = 460
    seal_x0 = (SIZE - seal_w) // 2
    seal_y0 = 130
    seal_x1 = seal_x0 + seal_w
    seal_y1 = seal_y0 + seal_h

    # Shadow
    draw.rounded_rectangle(
        [seal_x0 + 4, seal_y0 + 10, seal_x1 + 4, seal_y1 + 10],
        radius=96,
        fill=RED_SHADOW,
    )
    # Vermilion seal base
    draw.rounded_rectangle(
        [seal_x0, seal_y0, seal_x1, seal_y1], radius=96, fill=RED
    )

    # Gold inlay double frame
    ip = 18
    draw.rounded_rectangle(
        [seal_x0 + ip, seal_y0 + ip, seal_x1 - ip, seal_y1 - ip],
        radius=80,
        outline=GOLD,
        width=3,
    )
    draw.rounded_rectangle(
        [seal_x0 + ip + 6, seal_y0 + ip + 6, seal_x1 - ip - 6, seal_y1 - ip - 6],
        radius=74,
        outline=IVORY,
        width=1,
    )

    # 3. Celestial Moon + Sacred Lotus + Crown inside the seal
    cx = SIZE // 2
    cy = seal_y0 + (seal_h // 2) + 24

    # Crescent Moon
    moon_r = 120
    draw.ellipse(
        [cx - moon_r, cy - moon_r, cx + moon_r, cy + moon_r], fill=GOLD_LIGHT
    )
    draw.ellipse(
        [cx - moon_r + 48, cy - moon_r - 18, cx + moon_r + 32, cy + moon_r - 18],
        fill=RED,
    )

    # Sacred Lotus inside crescent
    lotus_y = cy + 26
    # Center petal
    draw.polygon(
        [(cx, lotus_y - 62), (cx - 18, lotus_y), (cx, lotus_y + 16), (cx + 18, lotus_y)],
        fill=IVORY,
    )
    # Side petals
    draw.polygon(
        [
            (cx - 30, lotus_y - 38),
            (cx - 46, lotus_y + 8),
            (cx - 16, lotus_y + 20),
            (cx, lotus_y + 12),
        ],
        fill=IVORY,
    )
    draw.polygon(
        [
            (cx + 30, lotus_y - 38),
            (cx + 46, lotus_y + 8),
            (cx + 16, lotus_y + 20),
            (cx, lotus_y + 12),
        ],
        fill=IVORY,
    )
    # Lotus gold base
    draw.chord(
        [cx - 52, lotus_y + 8, cx + 52, lotus_y + 34], start=0, end=180, fill=GOLD
    )

    # Imperial Crown positioned gracefully at the top of the seal
    crown_y = seal_y0 + 52
    crown_w = 170
    crown_h = 70
    band_y = crown_y + crown_h - 18
    # Crown base band
    draw.rounded_rectangle(
        [cx - crown_w // 2, band_y, cx + crown_w // 2, band_y + 14],
        radius=4,
        fill=GOLD,
    )
    # 3 Crown peaks
    spikes = [
        (cx - 58, 48),  # left
        (cx, 68),       # center highest
        (cx + 58, 48),  # right
    ]
    for sx, sh in spikes:
        draw.polygon(
            [(sx - 14, band_y), (sx, band_y - sh), (sx + 14, band_y)], fill=GOLD
        )
        draw.ellipse([sx - 9, band_y - sh - 18, sx + 9, band_y - sh], fill=GOLD_LIGHT)
    # Center jewel
    draw.ellipse([cx - 8, band_y + 1, cx + 8, band_y + 13], fill=RED)

    # 4. Typography beneath the seal
    font_brand = load_font("NewYork", 68)
    font_lifetime = load_font("SFProTextBold", 46)
    font_sub = load_font("SFProText", 22)

    # "AN NIÊN"
    draw.text((cx, 670), "AN NIÊN", font=font_brand, fill=INK, anchor="mm")

    # Vermilion badge capsule for "GÓI TRỌN ĐỜI"
    badge_w, badge_h = 420, 68
    bx0 = (SIZE - badge_w) // 2
    by0 = 740
    draw.rounded_rectangle(
        [bx0, by0, bx0 + badge_w, by0 + badge_h], radius=34, fill=RED
    )
    draw.text(
        (cx, by0 + (badge_h // 2)),
        "GÓI TRỌN ĐỜI",
        font=font_lifetime,
        fill=IVORY,
        anchor="mm",
    )

    # Divider with small diamond
    dy = 860
    line_w = 140
    draw.line([(cx - line_w - 24, dy), (cx - 24, dy)], fill=FRAME, width=2)
    draw.line([(cx + 24, dy), (cx + line_w + 24, dy)], fill=FRAME, width=2)
    draw.polygon(
        [(cx, dy - 8), (cx + 8, dy), (cx, dy + 8), (cx - 8, dy)], fill=GOLD
    )

    # Subtitle: "MỞ KHÓA VĨNH VIỄN · PREMIUM LIFETIME"
    draw.text(
        (cx, 915),
        "MỞ KHÓA VĨNH VIỄN · PREMIUM LIFETIME",
        font=font_sub,
        fill=ASH,
        anchor="mm",
    )

    img.save(output_path, "PNG", optimize=True)
    print(f"Rendered promotional image to: {output_path}")


if __name__ == "__main__":
    render_lifetime_promo(
        "/Users/lequangtrongtai/orca/Serene/docs/assets/promo-lifetime-1024.png"
    )
