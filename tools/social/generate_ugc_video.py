#!/usr/bin/env python3
"""
UGC Video Generation Pipeline for Training Arena.

Automates:
1. API-based generation via Replicate (Kling 1.5, MiniMax Hailuo, Wan 2.1)
2. Local high-definition FFmpeg cinematic preview compilation from keyframe anchors

Usage:
    # Compile dynamic preview video from anchor frames
    python tools/social/generate_ugc_video.py --mode preview \
        --frame1 "path/to/frame1.jpg" \
        --frame2 "path/to/frame2.jpg" \
        --output "ugc_pushup_defeat_preview.mp4"

    # Call Replicate Kling 1.5 Image-to-Video (requires REPLICATE_API_TOKEN)
    python tools/social/generate_ugc_video.py --mode replicate --engine kling \
        --image "path/to/frame1.jpg" \
        --prompt "..."

    Fal.ai mode is reserved and currently reports an unsupported-mode error.
"""

import argparse
import math
import os
import subprocess
import sys
from pathlib import Path

def create_preview_video(frame1: str, frame2: str, output_path: str, duration: int = 8) -> bool:
    """
    Synthesizes a realistic 9:16 vertical smartphone UGC clip using ffmpeg:
    - Segment 1: Handheld pushup plank with natural subtle camera sway and muscle exertion zoom.
    - Segment 2: Abrupt stop on rep 15, transition to defeat/shock reaction looking down at opponent's win on screen.
    """
    if not os.path.exists(frame1) or not os.path.exists(frame2):
        print(f"Error: One or both keyframes do not exist: {frame1}, {frame2}", file=sys.stderr)
        return False

    if duration <= 0:
        print("Error: Preview duration must be positive.", file=sys.stderr)
        return False
    fps = 30
    transition = min(0.5, duration / 2)
    # Each still is decoded once; zoompan expands it into the segment's frames.
    # Include the overlap in both segments, then bound the final output duration.
    segment_frames = math.ceil((duration + transition) * fps / 2)
    segment_duration = segment_frames / fps
    width = 720
    height = 1280

    cmd = [
        "ffmpeg", "-y",
        "-i", frame1,
        "-i", frame2,
        "-filter_complex",
        (
            f"[0:v]scale={width}:{height}:force_original_aspect_ratio=increase,crop={width}:{height},"
            f"zoompan=z='min(zoom+0.0006,1.05)':x='iw/2-(iw/zoom/2)+sin(time*2)*4':y='ih/2-(ih/zoom/2)+cos(time*2)*4':d={segment_frames}:s={width}x{height}:fps={fps}[v1];"
            f"[1:v]scale={width}:{height}:force_original_aspect_ratio=increase,crop={width}:{height},"
            f"zoompan=z='min(zoom+0.0004,1.04)':x='iw/2-(iw/zoom/2)+sin(time*1.5)*3':y='ih/2-(ih/zoom/2)+cos(time*1.5)*3':d={segment_frames}:s={width}x{height}:fps={fps}[v2];"
            f"[v1][v2]xfade=transition=fade:duration={transition}:offset={segment_duration-transition},format=yuv420p[outv]"
        ),
        "-map", "[outv]",
        "-t", str(duration),
        "-c:v", "libx264",
        "-crf", "22",
        "-preset", "medium",
        "-movflags", "+faststart",
        output_path
    ]

    print(f"Executing FFmpeg synthesis -> {output_path}")
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print("FFmpeg error:", res.stderr, file=sys.stderr)
        return False

    print(f"Preview video generated successfully: {output_path} ({os.path.getsize(output_path)} bytes)")
    return True

def run_replicate_i2v(image_path: str, prompt: str, engine: str, output_path: str) -> bool:
    api_token = os.getenv("REPLICATE_API_TOKEN")
    if not api_token:
        print("Error: REPLICATE_API_TOKEN environment variable is not set.", file=sys.stderr)
        print("Please export REPLICATE_API_TOKEN='...' or pass your API key.", file=sys.stderr)
        return False

    try:
        import replicate
    except ImportError:
        print("Error: replicate python package not found.", file=sys.stderr)
        return False

    models = {
        "kling": "kwaivgi/kling-v1.5",
        "minimax": "minimax/video-01",
        "wan": "wan-video/wan-2.1-14b"
    }

    model_id = models.get(engine, models["kling"])
    print(f"Sending Image-to-Video generation to Replicate ({model_id})...")

    with open(image_path, "rb") as f:
        output = replicate.run(
            model_id,
            input={
                "prompt": prompt,
                "input_image": f,
                "aspect_ratio": "9:16",
                "duration": 5
            }
        )

    print("Generation complete! Output URL:", output)
    import urllib.request
    urllib.request.urlretrieve(str(output), output_path)
    print(f"Video saved to: {output_path}")
    return True

def main():
    parser = argparse.ArgumentParser(description="Generate UGC video assets for Training Arena.")
    parser.add_argument("--mode", choices=["preview", "replicate", "fal"], default="preview")
    parser.add_argument("--engine", choices=["kling", "minimax", "wan"], default="kling")
    parser.add_argument("--frame1", help="Path to starting anchor frame (e.g. plank)")
    parser.add_argument("--frame2", help="Path to ending anchor frame (e.g. defeat)")
    parser.add_argument("--image", help="Single image for I2V API engines")
    parser.add_argument("--prompt", help="Motion prompt for I2V API engines")
    parser.add_argument("--output", default="ugc_output.mp4", help="Output file path")

    args = parser.parse_args()

    if args.mode == "fal":
        parser.error("Fal.ai mode is not implemented; use preview or replicate mode.")

    if args.mode == "preview":
        if not args.frame1 or not args.frame2:
            print("Error: --frame1 and --frame2 are required for preview mode.")
            sys.exit(1)
        success = create_preview_video(args.frame1, args.frame2, args.output)
        sys.exit(0 if success else 1)
    elif args.mode == "replicate":
        if not args.image or not args.prompt:
            print("Error: --image and --prompt are required for replicate mode.")
            sys.exit(1)
        success = run_replicate_i2v(args.image, args.prompt, args.engine, args.output)
        sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
