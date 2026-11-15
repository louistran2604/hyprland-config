import hashlib
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest


spec = importlib.util.spec_from_file_location("clock", Path(__file__).parents[1] / "scripts/HyprlockClock.py")
clock = importlib.util.module_from_spec(spec)
spec.loader.exec_module(clock)


class ClockTest(unittest.TestCase):
    def test_time_wallpaper_transparency_and_fallback(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            wallpaper = root / "wallpaper with spaces.png"
            alternate = root / "other wallpaper.png"
            for path, gradient in ((wallpaper, "gradient:#24618d-#bc718e"), (alternate, "gradient:#26883b-#ebc872")):
                subprocess.run(["convert", "-size", "640x360", gradient, str(path)], check=True)
            config, cache = root / "hyprlock.conf", root / "cache"

            def configure(path, tint="#96B3C4"):
                config.write_text(f"# clock-colors = {tint} #F1ECE8\nbackground {{\n    path = {path}\n}}\n")

            def digest(path):
                return hashlib.sha256(path.read_bytes()).hexdigest()

            configure(wallpaper)
            image = clock.render_clock(config, cache, "12:34")
            original, modified = digest(image), image.stat().st_mtime_ns
            pixels = subprocess.check_output([
                "convert", str(image), "-format", "%[pixel:p{0,0}] %[fx:maxima.a] %[fx:minima.a]", "info:",
            ], text=True).split()
            self.assertEqual(float(pixels[-1]), 0)
            self.assertAlmostEqual(float(pixels[-2]), 0.92, places=2)
            self.assertTrue(pixels[0].endswith(",0)"), pixels[0])
            rgb_count = int(subprocess.check_output([
                "convert", str(image), "-alpha", "off", "-format", "%k", "info:",
            ], text=True))
            self.assertGreater(rgb_count, 10, "Wallpaper texture must vary inside the digits")

            self.assertEqual(clock.render_clock(config, cache, "12:34"), image)
            self.assertEqual(image.stat().st_mtime_ns, modified, "Same minute should reuse the image")
            clock.render_clock(config, cache, "12:35")
            self.assertNotEqual(digest(image), original, "Minute change must redraw the digits")
            clock.render_clock(config, cache, "12:34")
            configure(alternate)
            clock.render_clock(config, cache, "12:34")
            self.assertNotEqual(digest(image), original, "Wallpaper change must update the texture")
            subprocess.run(["convert", "-size", "640x360", "gradient:#ab3571-#114688", str(alternate)], check=True)
            before_overwrite = digest(image)
            clock.render_clock(config, cache, "12:34")
            self.assertNotEqual(digest(image), before_overwrite, "Replaced wallpaper content must invalidate the cache")
            alternate_digest = digest(image)
            configure(alternate, "#e6a14e")
            clock.render_clock(config, cache, "12:34")
            self.assertNotEqual(digest(image), alternate_digest, "Wallust tint must affect the result")
            alternate.unlink()
            clock.render_clock(config, cache, "12:36")
            self.assertTrue(image.is_file(), "A removed wallpaper must still leave a readable clock")
            self.assertFalse(list(cache.glob("tmp*")), "Temporary render files must be cleaned up")
            last_good = digest(image)
            config.write_text("")
            with self.assertRaises(ValueError):
                clock.render_clock(config, cache, "12:37")
            self.assertEqual(digest(image), last_good, "Incomplete config must preserve the last good image")


if __name__ == "__main__":
    unittest.main()
