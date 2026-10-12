import math
from PIL import Image, ImageDraw, ImageFont

def render_app_icon(output_path):
    size = 1024
    img = Image.new("RGBA", (size, size), (254, 249, 241, 255)) # #FEF9F1
    draw = ImageDraw.Draw(img)

    # 1. Background subtle vignette & texture lines
    for r in range(size // 2, size):
        alpha = int(25 * (r - size // 2) / (size // 2))
        draw.ellipse([size//2 - r, size//2 - r, size//2 + r, size//2 + r], outline=(230, 222, 200, alpha), width=1)

    # Hairline outer traditional border frame
    pad = 64
    draw.rounded_rectangle([pad, pad, size - pad, size - pad], radius=160, outline=(230, 222, 200, 255), width=3)
    draw.rounded_rectangle([pad + 12, pad + 12, size - pad - 12, size - pad - 12], radius=148, outline=(197, 160, 89, 120), width=1)

    # 2. Main Center Seal (Ấn Triện Sơn Son)
    seal_pad = 180
    seal_rect = [seal_pad, seal_pad, size - seal_pad, size - seal_pad]

    # Shadow for seal
    shadow_offset = 12
    draw.rounded_rectangle([seal_pad + 4, seal_pad + shadow_offset, size - seal_pad + 4, size - seal_pad + shadow_offset], radius=110, fill=(158, 42, 43, 40))

    # Seal base fill (Imperial Vermilion #C23B22)
    draw.rounded_rectangle(seal_rect, radius=110, fill=(194, 59, 34, 255))

    # Inner gold seal inlay frame
    inner_pad = seal_pad + 20
    draw.rounded_rectangle([inner_pad, inner_pad, size - inner_pad, size - inner_pad], radius=90, outline=(197, 160, 89, 200), width=3)
    draw.rounded_rectangle([inner_pad + 8, inner_pad + 8, size - inner_pad - 8, size - inner_pad - 8], radius=82, outline=(254, 249, 241, 100), width=1)

    # 3. Center Celestial Lunar & Sacred Lotus Glyph
    cx, cy = size // 2, size // 2 - 30

    # Golden Crescent Moon
    moon_radius = 160
    # Outer circle
    draw.ellipse([cx - moon_radius, cy - moon_radius, cx + moon_radius, cy + moon_radius], fill=(233, 203, 143, 255))
    # Cutout circle for crescent effect
    draw.ellipse([cx - moon_radius + 60, cy - moon_radius - 20, cx + moon_radius + 40, cy + moon_radius - 20], fill=(194, 59, 34, 255))

    # Sacred Lotus Petals in Center
    lotus_y = cy + 50
    # Center petal
    draw.polygon([(cx, lotus_y - 80), (cx - 24, lotus_y), (cx, lotus_y + 20), (cx + 24, lotus_y)], fill=(254, 249, 241, 255))
    # Left petal
    draw.polygon([(cx - 40, lotus_y - 50), (cx - 60, lotus_y + 10), (cx - 20, lotus_y + 25), (cx, lotus_y + 15)], fill=(254, 249, 241, 230))
    # Right petal
    draw.polygon([(cx + 40, lotus_y - 50), (cx + 60, lotus_y + 10), (cx + 20, lotus_y + 25), (cx, lotus_y + 15)], fill=(254, 249, 241, 230))

    # Base Lotus Pedestal
    draw.chord([cx - 70, lotus_y + 10, cx + 70, lotus_y + 45], start=0, end=180, fill=(197, 160, 89, 255))

    # Star / Bindu above lotus
    star_r = 8
    draw.ellipse([cx - star_r, lotus_y - 105, cx + star_r, lotus_y - 105 + star_r * 2], fill=(233, 203, 143, 255))

    # 4. Typography "AN NIÊN" beneath the seal emblem
    try:
        font_serif = ImageFont.truetype("/System/Library/Fonts/NewYork.ttf", 64)
        font_sub = ImageFont.truetype("/System/Library/Fonts/SFProText.ttf", 26)
    except:
        font_serif = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    text_y = cy + 190
    draw.text((cx, text_y), "AN NIÊN", font=font_serif, fill=(254, 249, 241, 255), anchor="mm")

    sub_y = text_y + 52
    draw.text((cx, sub_y), "LỊCH VIỆT · NGÀY NHỚ", font=font_sub, fill=(233, 203, 143, 220), anchor="mm")

    img.save(output_path, "PNG")
    print(f"Successfully rendered AppIcon to {output_path}")

if __name__ == "__main__":
    render_app_icon("/Users/lequangtrongtai/orca/Serene/App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
