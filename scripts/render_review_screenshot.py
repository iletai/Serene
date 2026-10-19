"""Render the ASC "Review Information" screenshot: the paywall showing the Lifetime plan.

Mirrors App/Features/Paywall/PaywallView.swift layout (vi locale) at iPhone 16 Pro
logical size (393x852 pt @3x = 1179x2556 px) so reviewers see the IAP in context.
Dev-only script; regenerate after any paywall redesign.
"""

from PIL import Image, ImageDraw, ImageFont

# Design tokens (ColorTokens.swift / DESIGN.md)
BG = (254, 249, 241)          # New Rice Ivory
BG2 = (248, 243, 235)         # Woven Linen (card)
INK = (29, 28, 23)            # Deep Calligraphic Ink
ASH = (89, 65, 60)            # Hearth Ash
RED = (194, 59, 34)           # Imperial Vermilion
GOLD = (197, 160, 89)         # Imperial Chrysanthemum Gold
GOLD_BG = (243, 233, 212)     # gold container tint
BORDER = (226, 217, 199)
WHITE = (255, 255, 255)

SCALE = 3
W_PT, H_PT = 393, 852
W, H = W_PT * SCALE, H_PT * SCALE


def f(path_candidates, size):
    for p in path_candidates:
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            continue
    return ImageFont.load_default()


F_TITLE = f(["/System/Library/Fonts/NewYork.ttf"], 26 * SCALE)
F_HEAD = f(["/System/Library/Fonts/SFProText-Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"], 15 * SCALE)
F_BODY = f(["/System/Library/Fonts/SFProText-Regular.ttf", "/System/Library/Fonts/Helvetica.ttc"], 13 * SCALE)
F_CAP = f(["/System/Library/Fonts/SFProText-Regular.ttf", "/System/Library/Fonts/Helvetica.ttc"], 11 * SCALE)
F_BADGE = f(["/System/Library/Fonts/SFProText-Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"], 9 * SCALE)
F_CTA = f(["/System/Library/Fonts/SFProText-Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"], 16 * SCALE)


def rrect(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def check_row(d, y, text):
    cx = 24 * SCALE + 11 * SCALE
    d.ellipse([cx - 11 * SCALE, y - 11 * SCALE, cx + 11 * SCALE, y + 11 * SCALE], fill=GOLD_BG)
    d.line(
        [(cx - 5 * SCALE, y), (cx - 1.5 * SCALE, y + 3.5 * SCALE), (cx + 5 * SCALE, y - 3.5 * SCALE)],
        fill=RED, width=2 * SCALE,
    )
    d.text((cx + 16 * SCALE, y), text, font=F_BODY, fill=INK, anchor="lm")


def plan_card(d, y, name, desc, price, selected=False, badge=None):
    pad = 16 * SCALE
    x0, x1 = pad, W - pad
    h = 64 * SCALE
    box = [x0, y, x1, y + h]
    rrect(d, box, 14 * SCALE, fill=BG2, outline=RED if selected else BORDER, width=(2 if selected else 1) * SCALE)
    tx = x0 + 16 * SCALE
    d.text((tx, y + 18 * SCALE), name, font=F_HEAD, fill=INK)
    d.text((tx, y + 40 * SCALE), desc, font=F_CAP, fill=ASH)
    if badge:
        bx = tx + d.textlength(name, font=F_HEAD) + 8 * SCALE
        bw = d.textlength(badge, font=F_BADGE) + 12 * SCALE
        rrect(d, [bx, y + 12 * SCALE, bx + bw, y + 30 * SCALE], 9 * SCALE, fill=RED)
        d.text((bx + 6 * SCALE, y + 21 * SCALE), badge, font=F_BADGE, fill=WHITE, anchor="lm")
    d.text((x1 - 16 * SCALE, y + h / 2), price, font=F_HEAD, fill=RED if selected else INK, anchor="rm")
    return y + h + 10 * SCALE


def render(path):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    # Status bar
    d.text((30 * SCALE, 24 * SCALE), "9:41", font=F_BODY, fill=INK, anchor="lm")

    # Close button
    rrect(d, [W - 52 * SCALE, 44 * SCALE, W - 20 * SCALE, 76 * SCALE], 12 * SCALE, fill=BG2, outline=BORDER)
    d.line([(W - 42 * SCALE, 54 * SCALE), (W - 30 * SCALE, 66 * SCALE)], fill=INK, width=2 * SCALE)
    d.line([(W - 42 * SCALE, 66 * SCALE), (W - 30 * SCALE, 54 * SCALE)], fill=INK, width=2 * SCALE)

    # Hero
    cx = W // 2
    # Crown glyph (gold)
    cy0 = 108 * SCALE
    cw, ch = 22 * SCALE, 16 * SCALE
    for sx, sh in [(cx - 14 * SCALE, 10 * SCALE), (cx, 16 * SCALE), (cx + 14 * SCALE, 10 * SCALE)]:
        d.polygon([(sx - 5 * SCALE, cy0), (sx, cy0 - sh), (sx + 5 * SCALE, cy0)], fill=GOLD)
        d.ellipse([sx - 3 * SCALE, cy0 - sh - 6 * SCALE, sx + 3 * SCALE, cy0 - sh], fill=GOLD)
    d.rectangle([cx - cw, cy0, cx + cw, cy0 + 6 * SCALE], fill=GOLD)

    # Seal badge "AN NIÊN"
    sw, sh2 = 78 * SCALE, 44 * SCALE
    sx0, sy0 = cx - sw, 126 * SCALE
    rrect(d, [sx0, sy0, sx0 + 2 * sw, sy0 + sh2], 6 * SCALE, fill=BG, outline=RED, width=2 * SCALE)
    d.text((cx, sy0 + sh2 / 2), "AN NIÊN", font=F_HEAD, fill=RED, anchor="mm")

    # Titles
    d.text((cx, sy0 + sh2 + 34 * SCALE), "An Niên Gia Tộc", font=F_TITLE, fill=INK, anchor="mm")
    sub = "Lưu giữ trọn vẹn ký ức tổ tiên & bản sắc gia đình Việt"
    d.text((cx, sy0 + sh2 + 60 * SCALE), sub, font=F_BODY, fill=ASH, anchor="mm")

    # Feature card
    fy0 = sy0 + sh2 + 80 * SCALE
    rows = [
        "Không giới hạn ngày giỗ & thông báo thông minh",
        "Đồng bộ phả hệ & gia tộc qua iCloud",
        "Chế Độ Gia Phả Thu Nhỏ",
        "Widget Màn hình khóa & Can Chi chuyên sâu",
    ]
    fh = 30 * SCALE * len(rows) + 24 * SCALE
    rrect(d, [16 * SCALE, fy0, W - 16 * SCALE, fy0 + fh], 16 * SCALE, fill=BG2, outline=BORDER)
    for i, t in enumerate(rows):
        check_row(d, fy0 + 24 * SCALE + i * 30 * SCALE, t)

    # Plans (lifetime selected, price $9.99 as set on ASC)
    py = fy0 + fh + 18 * SCALE
    py = plan_card(d, py, "Gói Tháng Pro", "Mở khóa toàn bộ tính năng theo tháng", "39.000 đ")
    py = plan_card(d, py, "Gói Năm Pro", "Mở khóa toàn bộ tính năng 1 năm (Dùng thử 7 ngày)",
                   "199.000 đ", badge="DÙNG THỬ 7 NGÀY")
    py = plan_card(d, py, "An Niên Vĩnh Viễn", "Truy cập trọn đời tất cả tính năng Pro", "$9.99",
                   selected=True)

    # CTA
    cy1 = py + 8 * SCALE
    rrect(d, [16 * SCALE, cy1, W - 16 * SCALE, cy1 + 52 * SCALE], 14 * SCALE, fill=RED)
    d.text((cx, cy1 + 26 * SCALE), "Nâng Cấp An Niên Pro", font=F_CTA, fill=WHITE, anchor="mm")

    # Restore + legal
    d.text((cx, cy1 + 78 * SCALE), "Khôi phục mua hàng", font=F_CAP, fill=ASH, anchor="mm")
    ly = H - 40 * SCALE
    t1, t2 = "Điều khoản sử dụng", "Chính sách bảo mật"
    w1 = d.textlength(t1, font=F_CAP)
    w2 = d.textlength(t2, font=F_CAP)
    gap = 28 * SCALE
    x = cx - (w1 + gap + w2) / 2
    d.text((x, ly), t1, font=F_CAP, fill=ASH)
    d.text((x + w1 + gap, ly), t2, font=F_CAP, fill=ASH)

    # Home indicator
    rrect(d, [cx - 67 * SCALE, H - 18 * SCALE, cx + 67 * SCALE, H - 12 * SCALE], 3 * SCALE, fill=INK)
    img.save(path, "PNG", optimize=True)
    print(f"Rendered {path} ({W}x{H})")


if __name__ == "__main__":
    render("/Users/lequangtrongtai/orca/Serene/docs/assets/review-screenshot-paywall.png")
