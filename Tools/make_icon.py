from PIL import Image, ImageDraw
from pathlib import Path

SIZE = 1024
SCALE = 4
BIG = SIZE * SCALE


def hex_color(hex_str):
    hex_str = hex_str.lstrip("#")
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))


DEEP_EMERALD = hex_color("#0B6B50")
FRESH_MINT = hex_color("#DDF4EA")
WARM_IVORY = hex_color("#FAF9F5")
INK = hex_color("#17211D")
SOFT_GOLD = hex_color("#E9C46A")
WHITE = (255, 255, 255)


def gradient_background(draw, top, bottom, width=BIG, height=BIG):
    for y in range(height):
        t = y / (height - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b))


def shield_points(cx, cy, w, h):
    top_y = cy - h // 2
    return [
        (cx - w // 2, top_y + int(h * 0.12)),
        (cx - w // 2, top_y + int(h * 0.70)),
        (cx, top_y + h),
        (cx + w // 2, top_y + int(h * 0.70)),
        (cx + w // 2, top_y + int(h * 0.12)),
        (cx, top_y),
    ]


def draw_rounded_polyline(draw, points, color, width_px):
    lw = width_px * SCALE
    for i in range(len(points) - 1):
        draw.line([points[i], points[i + 1]], fill=color, width=lw, joint="curve")
    for p in points:
        r = lw / 2
        draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)


def make_icon(variant, out_dir):
    img = Image.new("RGB", (BIG, BIG), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    if variant == "light":
        gradient_background(draw, DEEP_EMERALD, INK)
        shield_fill = WARM_IVORY
        check_color = DEEP_EMERALD
        accent = SOFT_GOLD
    elif variant == "dark":
        gradient_background(draw, (10, 35, 26), (6, 12, 10))
        shield_fill = (232, 231, 226)
        check_color = (47, 190, 143)
        accent = (213, 183, 106)
    elif variant == "tinted":
        draw.rectangle([0, 0, BIG, BIG], fill=(128, 128, 128))
        shield_fill = (255, 255, 255)
        check_color = (50, 50, 50)
        accent = (160, 160, 160)
    else:
        raise ValueError(variant)

    cx, cy = BIG // 2, BIG // 2 - int(BIG * 0.03)
    w, h = int(BIG * 0.46), int(BIG * 0.56)

    outline_w = 10 if variant == "tinted" else 14
    outline_points = shield_points(cx, cy, w + outline_w * SCALE * 2, h + outline_w * SCALE * 2)
    draw.polygon(outline_points, fill=accent)

    points = shield_points(cx, cy, w, h)
    draw.polygon(points, fill=shield_fill)

    ck_w = int(BIG * 0.28)
    ck_h = int(BIG * 0.22)
    p1 = (cx - int(ck_w * 0.45), cy + int(ck_h * 0.05))
    p2 = (cx - int(ck_w * 0.08), cy + int(ck_h * 0.45))
    p3 = (cx + int(ck_w * 0.55), cy - int(ck_h * 0.45))
    line_w = 44 if variant == "tinted" else 48
    draw_rounded_polyline(draw, [p1, p2, p3], check_color, line_w)

    dot_y = cy + h // 2 - int(BIG * 0.02)
    dot_r = int(BIG * 0.028)
    dot_color = (200, 200, 200) if variant == "tinted" else SOFT_GOLD
    draw.ellipse([cx - dot_r, dot_y - dot_r, cx + dot_r, dot_y + dot_r], fill=dot_color)

    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    out_path = out_dir / f"AppIcon-{variant}-1024.png"
    img.save(out_path, "PNG")
    print(f"wrote {out_path}")
    return out_path


if __name__ == "__main__":
    # This script lives at Tools/make_icon.py relative to the repo root.
    repo_root = Path(__file__).resolve().parents[1]
    out_dir = repo_root / "Redress" / "Assets.xcassets" / "AppIcon.appiconset"
    out_dir.mkdir(parents=True, exist_ok=True)

    for variant in ["light", "dark", "tinted"]:
        make_icon(variant, out_dir)
