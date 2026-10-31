import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from tools.social.generate_ugc_video import create_preview_video


class TestUgcVideo(unittest.TestCase):
    def test_fal_mode_fails_explicitly_without_creating_output(self):
        script = Path(__file__).with_name('generate_ugc_video.py')
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'fal.mp4'
            result = subprocess.run([sys.executable, str(script), '--mode', 'fal', '--output', str(output)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Fal.ai mode is not implemented', result.stderr)
            self.assertFalse(output.exists())

    @unittest.skipUnless(shutil.which('ffmpeg') and shutil.which('ffprobe'), 'FFmpeg and ffprobe required')
    def test_preview_uses_both_stills_and_honors_duration(self):
        with tempfile.TemporaryDirectory() as directory:
            frames = [Path(directory) / f'{color}.png' for color in ('red', 'blue')]
            for frame, color in zip(frames, ('red', 'blue')):
                subprocess.run(['ffmpeg', '-v', 'error', '-f', 'lavfi', '-i', f'color=c={color}:s=90x160', '-frames:v', '1', str(frame)], check=True, capture_output=True)
            for duration in (8, 2):
                output = Path(directory) / f'preview-{duration}.mp4'
                self.assertTrue(create_preview_video(str(frames[0]), str(frames[1]), str(output), duration=duration))
                probe = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height,r_frame_rate,nb_frames:format=duration', '-of', 'json', str(output)], check=True, capture_output=True, text=True)
                info = json.loads(probe.stdout)
                self.assertAlmostEqual(float(info['format']['duration']), duration, delta=1 / 30)
                self.assertEqual(int(info['streams'][0]['nb_frames']), duration * 30)
                self.assertEqual((info['streams'][0]['width'], info['streams'][0]['height']), (720, 1280))
                self.assertEqual(info['streams'][0]['r_frame_rate'], '30/1')
                for timestamp, channel in ((0, 0), (duration - 0.1, 2)):
                    pixel = subprocess.run(['ffmpeg', '-v', 'error', '-ss', str(timestamp), '-i', str(output), '-frames:v', '1', '-vf', 'scale=1:1', '-pix_fmt', 'rgb24', '-f', 'rawvideo', '-'], check=True, capture_output=True).stdout
                    self.assertEqual(len(pixel), 3)
                    self.assertGreater(pixel[channel], 200)
                    self.assertLess(pixel[2 - channel], 30)


if __name__ == '__main__':
    unittest.main()
