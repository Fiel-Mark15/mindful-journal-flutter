"""Generate native icon sizes from the approved artwork; never draw a new mark.

Run with Flutter/Dart on PATH. iOS is the only configured runner. The master
PNG is read only. Existing launch-image sizes are refreshed without editing
its storyboard, colors, background, padding, or layout.
"""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets/images/app_icon.png"
if not MASTER.is_file():
    raise SystemExit(f"Missing approved master artwork: {MASTER}")
subprocess.run(["dart", "run", "flutter_launcher_icons"], cwd=ROOT, check=True)
launch = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
for spec in json.loads((launch / "Contents.json").read_text())["images"]:
    size = 80 * int(spec["scale"].removesuffix("x"))
    subprocess.run(["sips", "-z", str(size), str(size), str(MASTER),
                    "--out", str(launch / spec["filename"])], check=True)
print("Generated iOS icons and refreshed the existing branded launch images.")
