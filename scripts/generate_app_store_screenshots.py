import os
from PIL import Image, ImageDraw, ImageFont

def create_screenshot(title, subtitle, badge, output_path, width=1206, height=2622):
    # Base canvas: RGB, New Rice Ivory (#FEF9F1)
    img = Image.new("RGB", (width, height), (254, 249, 241))
    draw = ImageDraw.Draw(img)

    # Subtle traditional border frame (Gold #C5A059)
    pad = 48
    draw.rounded_rectangle([pad, pad, width - pad, height - pad], radius=60, outline=(197, 160, 89), width=3)
    draw.rounded_rectangle([pad + 12, pad + 12, width - pad - 12, height - pad - 12], radius=48, outline=(197, 160, 89), width=1)

    # Top Header section
    try:
        font_badge = ImageFont.truetype("/System/Library/Fonts/SFProText-Medium.ttf", 32)
        font_title = ImageFont.truetype("/System/Library/Fonts/NewYork.ttf", 72)
        font_sub = ImageFont.truetype("/System/Library/Fonts/SFProText.ttf", 38)
    except:
        font_badge = ImageFont.load_default()
        font_title = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    # Badge (Cinnabar Red background #C23B22, White text)
    badge_w, badge_h = 420, 64
    badge_x = (width - badge_w) // 2
    badge_y = 140
    draw.rounded_rectangle([badge_x, badge_y, badge_x + badge_w, badge_y + badge_h], radius=32, fill=(194, 59, 34))
    draw.text((width // 2, badge_y + badge_h // 2), badge.upper(), font=font_badge, fill=(254, 249, 241), anchor="mm")

    # Title (Deep Calligraphic Ink #1D1C17)
    draw.text((width // 2, badge_y + 130), title, font=font_title, fill=(29, 28, 23), anchor="mm", align="center")

    # Subtitle (Hearth Ash #59413C)
    draw.text((width // 2, badge_y + 220), subtitle, font=font_sub, fill=(89, 65, 60), anchor="mm", align="center")

    # Mockup phone screen container (Simulated app interface)
    mock_x1, mock_y1 = 120, badge_y + 320
    mock_x2, mock_y2 = width - 120, height - 160

    # Phone frame background (Woven Linen #F8F3EB)
    draw.rounded_rectangle([mock_x1, mock_y1, mock_x2, mock_y2], radius=50, fill=(248, 243, 235), outline=(197, 160, 89), width=4)

    # Inner App Content Header Mockup inside phone
    inner_cx = width // 2
    inner_top = mock_y1 + 80

    # Lunar Date Card Mockup inside phone
    card_w, card_h = mock_x2 - mock_x1 - 100, 320
    card_x = mock_x1 + 50
    card_y = inner_top
    draw.rounded_rectangle([card_x, card_y, card_x + card_w, card_y + card_h], radius=30, fill=(254, 249, 241), outline=(197, 160, 89), width=2)

    try:
        font_lunar_big = ImageFont.truetype("/System/Library/Fonts/NewYork.ttf", 96)
        font_lunar_sub = ImageFont.truetype("/System/Library/Fonts/SFProText-Medium.ttf", 36)
    except:
        font_lunar_big = ImageFont.load_default()
        font_lunar_sub = ImageFont.load_default()

    draw.text((inner_cx, card_y + 110), "15 · ÂM LỊCH", font=font_lunar_big, fill=(194, 59, 34), anchor="mm")
    draw.text((inner_cx, card_y + 210), "Tháng Chạp • Năm Ất Tỵ", font=font_lunar_sub, fill=(29, 28, 23), anchor="mm")
    draw.text((inner_cx, card_y + 260), "Giờ Hoàng Đạo: Tý (23h-01h), Dần (03h-05h)", font=font_sub, fill=(197, 160, 89), anchor="mm")

    # Calendar Grid Mockup
    grid_y = card_y + card_h + 50
    grid_w = card_w
    grid_h = 750
    draw.rounded_rectangle([card_x, grid_y, card_x + grid_w, grid_y + grid_h], radius=30, fill=(254, 249, 241), outline=(197, 160, 89), width=2)

    days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    col_w = grid_w // 7
    for i, d in enumerate(days):
        dx = card_x + i * col_w + col_w // 2
        draw.text((dx, grid_y + 50), d, font=font_sub, fill=(89, 65, 60), anchor="mm")

    cell_h = 95
    start_y = grid_y + 110
    solar_day = 1
    for r in range(6):
        for c in range(7):
            cx = card_x + c * col_w + col_w // 2
            cy = start_y + r * cell_h + cell_h // 2

            if solar_day == 15:
                draw.ellipse([cx - 36, cy - 36, cx + 36, cy + 36], fill=(194, 59, 34))
                draw.text((cx, cy - 8), str(solar_day), font=font_sub, fill=(254, 249, 241), anchor="mm")
            elif solar_day <= 30:
                draw.text((cx, cy), str(solar_day), font=font_sub, fill=(29, 28, 23), anchor="mm")
            solar_day += 1

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, "PNG")
    print(f"Generated RGB screenshot: {output_path}")

if __name__ == "__main__":
    out_dir = "/Users/lequangtrongtai/orca/Serene/fastlane/screenshots/vi"
    os.makedirs(out_dir, exist_ok=True)

    create_screenshot(
        "Âm Dương Lịch Chính Xác",
        "Độ chính xác thiên văn GMT+7 tuyệt đối",
        "Lịch Việt & Ngày Nhớ",
        os.path.join(out_dir, "1_lunar_calendar.png")
    )
    create_screenshot(
        "24 Tiết Khí & Hoàng Đạo",
        "Nắm bắt giờ hoàng đạo và tiết khí chuẩn xác",
        "Phong Thủy & Thời Gian",
        os.path.join(out_dir, "2_solar_terms.png")
    )
    create_screenshot(
        "Quản Lý Ngày Giỗ Chạp",
        "Không bao giờ quên ngày kỷ niệm quan trọng",
        "Nhắc Nhở Thông Minh",
        os.path.join(out_dir, "3_memorials.png")
    )
