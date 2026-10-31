#!/usr/bin/env python3
"""
UGC Prompt Matrix Generator for Training Arena.

Generates photorealistic, amateur-style UGC video prompts designed for:
- 4x Gemini Pro accounts (Imagen 3 / Google AI Studio) & Codex Plus (DALL-E 3)
- Free Video Engines: Kling AI 1.5, Hailuo AI (MiniMax), Wan 2.1, Hedra

Usage:
    python tools/social/ugc_prompt_matrix.py --type all --exercise pushup
    python tools/social/ugc_prompt_matrix.py --type hook --count 3
"""

import argparse
import json
import random
import sys
from typing import Dict, List, Any

PERSONAS = [
    {
        "name": "Athletic male mid-20s",
        "description": "athletic 26-year-old male with messy brown hair wearing an oversized grey workout t-shirt and dark gym shorts"
    },
    {
        "name": "Active female late-20s",
        "description": "energetic 28-year-old woman with hair in a messy ponytail wearing black athletic leggings and a fitted tank top"
    },
    {
        "name": "Fit male early-30s",
        "description": "fit 32-year-old man with light stubble wearing a navy blue cotton training shirt and track pants"
    },
    {
        "name": "Athletic female mid-20s",
        "description": "athletic 24-year-old woman wearing olive green compression tights and a casual oversized t-shirt"
    }
]

SETTINGS = [
    "a normal apartment living room with hardwood floors, a yoga mat laid out, and natural daylight coming from a side window",
    "a casual bedroom with carpeted floor, light clutter in background, and warm overhead ceiling light",
    "a clean domestic garage gym with rubber floor tiles and a water bottle resting nearby",
    "a compact studio apartment living area with a sofa in the soft background and clear floor space"
]

UGC_CAMERA_PROMPTS = [
    "Shot on iPhone 12 front camera, vertical 9:16 aspect ratio, authentic TikTok video still, natural uneven indoor lighting, subtle motion blur, authentic skin texture with natural imperfections, unedited amateur UGC aesthetic",
    "Amateur smartphone vertical 9:16 capture, handheld perspective, soft natural room light, candid fitness content, realistic athletic posture, zero studio lighting, genuine social media video still",
    "Raw vertical 9:16 mobile phone video frame, casual home workout vibe, authentic grain, natural exposure, realistic domestic background, uncurated social media look"
]

def generate_type_a_hook(persona: Dict[str, str], setting: str, exercise: str) -> Dict[str, Any]:
    camera = random.choice(UGC_CAMERA_PROMPTS)
    base_image_prompt = (
        f"Vertical 9:16 handheld selfie shot of an {persona['description']} in {setting}. "
        f"Holding phone at arm's length looking directly into the camera lens with a playful competitive smirk. "
        f"{camera}."
    )
    motion_prompt = (
        "Handheld phone selfie video. The person speaks directly into camera with natural head tilt and micro-expressions, "
        "raises eyebrows playfully, slight natural handheld jitter of someone holding a smartphone at arm's length. "
        "Background remains stable and natural."
    )
    return {
        "asset_type": "Type A: Hook / Callout (0-3s)",
        "recommended_engine": "Hedra (talking head) / Hailuo AI (reaction & expressions)",
        "base_image_prompt_for_gemini_or_codex": base_image_prompt,
        "video_motion_prompt_for_video_engine": motion_prompt,
        "parameters": {
            "aspect_ratio": "9:16",
            "motion_strength": 3,
            "target_duration_seconds": 3
        }
    }

def generate_type_b_workout(persona: Dict[str, str], setting: str, exercise: str) -> Dict[str, Any]:
    camera = random.choice(UGC_CAMERA_PROMPTS)
    if exercise == "pushup":
        pose_desc = "in full plank push-up position with palms on the floor, elbows slightly bent, straight body line"
        motion_desc = (
            "Static low-angle camera. The person performs smooth, disciplined push-ups: lowering chest to 2 inches off floor, "
            "then pushing back up to top plank position. Natural breathing cadence, continuous steady repetitions."
        )
    else:
        pose_desc = "standing in ready athletic squat position with feet shoulder-width apart, arms raised for balance"
        motion_desc = (
            "Static low-angle camera. The person performs smooth bodyweight squats: hips descending below parallel, "
            "then driving back up to full standing posture. Natural tempo and continuous motion."
        )

    base_image_prompt = (
        f"Vertical 9:16 wide floor-level shot inside {setting}. A smartphone is propped against a water bottle in the lower foreground. "
        f"In the middle ground, {persona['description']} is {pose_desc}. "
        f"{camera}."
    )
    return {
        "asset_type": f"Type B: Phone Setup & Reps ({exercise}) (5-10s)",
        "recommended_engine": "Kling AI 1.5 (Image-to-Video) / Wan 2.1 / Viggle AI",
        "base_image_prompt_for_gemini_or_codex": base_image_prompt,
        "video_motion_prompt_for_video_engine": motion_desc,
        "parameters": {
            "aspect_ratio": "9:16",
            "motion_strength": 4,
            "target_duration_seconds": 6
        }
    }

def generate_type_c_reaction(persona: Dict[str, str], setting: str, exercise: str) -> Dict[str, Any]:
    camera = random.choice(UGC_CAMERA_PROMPTS)
    base_image_prompt = (
        f"Vertical 9:16 ground-level shot in {setting}. An {persona['description']} sits back on their knees, catching breath with light sweat "
        f"on forehead, smiling and reaching one hand towards the propped phone on the floor. "
        f"{camera}."
    )
    motion_prompt = (
        "Ground-level camera. The person sits back on knees, breathes deeply with chest rising and falling, laughs out of breath, "
        "and reaches forward to tap the phone screen with a surprised reaction. Natural lighting and organic human movement."
    )
    return {
        "asset_type": "Type C: Fatigue & Screen Reaction (3-5s)",
        "recommended_engine": "Hailuo AI / Kling AI 1.5",
        "base_image_prompt_for_gemini_or_codex": base_image_prompt,
        "video_motion_prompt_for_video_engine": motion_prompt,
        "parameters": {
            "aspect_ratio": "9:16",
            "motion_strength": 3,
            "target_duration_seconds": 4
        }
    }

def generate_matrix(shot_type: str, exercise: str, count: int) -> List[Dict[str, Any]]:
    results = []
    types_to_generate = ["hook", "workout", "reaction"] if shot_type == "all" else [shot_type]

    for _ in range(count):
        persona = random.choice(PERSONAS)
        setting = random.choice(SETTINGS)
        for t in types_to_generate:
            if t == "hook":
                results.append(generate_type_a_hook(persona, setting, exercise))
            elif t == "workout":
                results.append(generate_type_b_workout(persona, setting, exercise))
            elif t == "reaction":
                results.append(generate_type_c_reaction(persona, setting, exercise))
    return results

def format_output(results: List[Dict[str, Any]]) -> str:
    lines = ["=" * 80, "TRAINING ARENA: AI UGC VIDEO GENERATION PROMPTS", "=" * 80, ""]
    for i, item in enumerate(results, 1):
        lines.append(f"[{i}] {item['asset_type']}")
        lines.append(f"Recommended Video Engine: {item['recommended_engine']}")
        lines.append(f"Aspect Ratio: {item['parameters']['aspect_ratio']} | Motion: {item['parameters']['motion_strength']} | Target: {item['parameters']['target_duration_seconds']}s")
        lines.append("")
        lines.append("Step 1: Anchor Image Prompt (Gemini Pro / Imagen 3 or Codex DALL-E 3):")
        lines.append(f"  \"{item['base_image_prompt_for_gemini_or_codex']}\"")
        lines.append("")
        lines.append("Step 2: Video Motion Prompt (Kling / Hailuo / Wan 2.1):")
        lines.append(f"  \"{item['video_motion_prompt_for_video_engine']}\"")
        lines.append("-" * 80)
        lines.append("")
    return "\n".join(lines)

def main():
    parser = argparse.ArgumentParser(description="Generate UGC video prompts for Training Arena.")
    parser.add_argument("--type", choices=["hook", "workout", "reaction", "all"], default="all", help="Shot type to generate")
    parser.add_argument("--exercise", choices=["pushup", "squat"], default="pushup", help="Exercise movement")
    parser.add_argument("--count", type=int, default=1, help="Number of variations per type")
    parser.add_argument("--json", action="store_true", help="Output raw JSON")

    args = parser.parse_args()
    results = generate_matrix(args.type, args.exercise, args.count)

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print(format_output(results))

if __name__ == "__main__":
    main()
