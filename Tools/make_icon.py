from PIL import Image, ImageDraw
import math

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

# Deep teal-to-navy gradient background (distinct from Kestrel's warm dusk gradient)
top = (12, 74, 84)
bottom = (8, 32, 56)
for y in range(SIZE):
    t = y / SIZE
    r = int(top[0] + (bottom[0] - top[0]) * t)
    g = int(top[1] + (bottom[1] - top[1]) * t)
    b = int(top[2] + (bottom[2] - top[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

# Shield outline — "protected claim" mark, kept simple enough to read at
# home-screen size (the mark IS the product, not a logo lockup)
cx, cy = SIZE // 2, SIZE // 2 - 20
w, h = 460, 560
top_y = cy - h // 2
points = [
    (cx - w // 2, top_y + 60),
    (cx - w // 2, top_y + h - 160),
    (cx, top_y + h),
    (cx + w // 2, top_y + h - 160),
    (cx + w // 2, top_y + 60),
    (cx, top_y),
]
draw.polygon(points, fill=(240, 246, 244))

# Checkmark inside the shield — claim resolved / made whole
ck_color = (12, 74, 84)
lw = 46
p1 = (cx - 130, cy + 10)
p2 = (cx - 30, cy + 110)
p3 = (cx + 150, cy - 130)
draw.line([p1, p2], fill=ck_color, width=lw, joint="curve")
draw.line([p2, p3], fill=ck_color, width=lw, joint="curve")
for p in (p1, p2, p3):
    draw.ellipse([p[0]-lw/2, p[1]-lw/2, p[0]+lw/2, p[1]+lw/2], fill=ck_color)

img.save("/Users/dj/Documents/Redress/Redress/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
print("wrote icon")
