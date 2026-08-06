#!/usr/bin/env python3

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


CANVAS_SIZE = 1024
ICON_FILES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}


def make_alpha_mask() -> Image.Image:
    scale = 4
    mask = Image.new("L", (CANVAS_SIZE * scale, CANVAS_SIZE * scale), 0)
    draw = ImageDraw.Draw(mask)
    bounds = tuple(value * scale for value in (96, 103, 928, 932))
    draw.rounded_rectangle(bounds, radius=205 * scale, fill=255)
    return mask.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)


def make_master(source: Path) -> Image.Image:
    image = Image.open(source).convert("RGBA")
    image = image.resize((CANVAS_SIZE, CANVAS_SIZE), Image.Resampling.LANCZOS)
    image.putalpha(make_alpha_mask())
    return image


def write_checkerboard_preview(image: Image.Image, destination: Path) -> None:
    tile = 32
    preview = Image.new("RGB", image.size, "white")
    draw = ImageDraw.Draw(preview)
    for y in range(0, CANVAS_SIZE, tile):
        for x in range(0, CANVAS_SIZE, tile):
            if (x // tile + y // tile) % 2:
                draw.rectangle((x, y, x + tile - 1, y + tile - 1), fill="#D7D9DE")
    preview.paste(image, mask=image.getchannel("A"))
    preview.save(destination, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate SnapPii macOS icon assets")
    parser.add_argument("source", type=Path)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--preview", type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    artwork_directory = root / "ScreenshotTool/Resources/Artwork"
    app_icon_directory = root / "ScreenshotTool/Resources/Assets.xcassets/AppIcon.appiconset"
    logo_directories = [
        root / "ScreenshotTool/Resources/Assets.xcassets/AppLogoLight.imageset",
        root / "ScreenshotTool/Resources/Assets.xcassets/AppLogoDark.imageset",
    ]

    master = make_master(args.source)
    artwork_directory.mkdir(parents=True, exist_ok=True)
    master.save(artwork_directory / "SnapPiiIcon.png", optimize=True)

    for filename, size in ICON_FILES.items():
        resized = master.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(app_icon_directory / filename, optimize=True)

    for directory in logo_directories:
        master.save(directory / "logo.png", optimize=True)

    if args.preview:
        write_checkerboard_preview(master, args.preview)


if __name__ == "__main__":
    main()
