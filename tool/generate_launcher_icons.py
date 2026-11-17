"""Package the approved foreground into launcher assets (requires Pillow)."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets/branding"
RES = ROOT / "android/app/src/main/res"
FOREST = "#244C3F"


def main():
    foreground = Image.open(BRANDING / "launcher-foreground.png").convert("RGBA")
    if foreground.width != foreground.height:
        raise ValueError("The adaptive foreground must be square")
    if foreground.getextrema()[3][0] != 0:
        raise ValueError("The adaptive foreground must have transparent padding")

    # Android layers use 108dp; launchers show their central 72dp viewport.
    composite = Image.new("RGBA", foreground.size, FOREST)
    composite.alpha_composite(foreground)
    inset = foreground.width / 6
    tile = composite.crop(
        (round(inset), round(inset), round(foreground.width - inset),
         round(foreground.height - inset))
    )
    tile.resize((512, 512), Image.Resampling.LANCZOS).convert("RGB").save(
        BRANDING / "launcher-icon.png"
    )

    for density, scale in (
        ("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2),
        ("xxhdpi", 3), ("xxxhdpi", 4),
    ):
        directory = RES / f"mipmap-{density}"
        directory.mkdir(parents=True, exist_ok=True)
        foreground.resize(
            (round(108 * scale), round(108 * scale)), Image.Resampling.LANCZOS
        ).save(directory / "ic_launcher_foreground.png")
        tile.resize(
            (round(48 * scale), round(48 * scale)), Image.Resampling.LANCZOS
        ).save(directory / "ic_launcher.png")

    for size in (192, 512):
        icon = tile.resize((size, size), Image.Resampling.LANCZOS).convert("RGB")
        for filename in (f"Icon-{size}.png", f"Icon-maskable-{size}.png"):
            icon.save(ROOT / "web/icons" / filename)
    tile.resize((32, 32), Image.Resampling.LANCZOS).save(ROOT / "web/favicon.png")
    tile.resize((256, 256), Image.Resampling.LANCZOS).save(
        ROOT / "windows/runner/resources/app_icon.ico",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )

    # Preview both OEM masks and a real launcher-sized version.
    preview = Image.new("RGB", (840, 360), "#F6F4EF")
    for x, radius in ((40, 140), (340, 64)):
        icon = tile.resize((280, 280), Image.Resampling.LANCZOS)
        mask = Image.new("L", icon.size)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 279, 279), radius, fill=255)
        preview.paste(icon, (x, 40), mask)
    preview.paste(tile.resize((48, 48), Image.Resampling.LANCZOS), (720, 156))
    preview.save(BRANDING / "launcher-preview.png")
    print("Generated Android, web, Windows and preview icons.")
    print(f"Source: {foreground.size}; visible alpha bounds: {foreground.getchannel('A').getbbox()}")


if __name__ == "__main__":
    main()
