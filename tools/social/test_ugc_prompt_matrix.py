#!/usr/bin/env python3
"""
Unit tests for UGC Prompt Matrix Generator.
"""

import unittest
from tools.social.ugc_prompt_matrix import (
    PERSONAS,
    SETTINGS,
    generate_type_a_hook,
    generate_type_b_workout,
    generate_type_c_reaction,
    generate_matrix,
    format_output
)

class TestUgcPromptMatrix(unittest.TestCase):
    def setUp(self):
        self.persona = PERSONAS[0]
        self.setting = SETTINGS[0]

    def test_generate_type_a_hook(self):
        item = generate_type_a_hook(self.persona, self.setting, "pushup")
        self.assertIn("Type A: Hook", item["asset_type"])
        self.assertIn("Hedra", item["recommended_engine"])
        self.assertEqual(item["parameters"]["aspect_ratio"], "9:16")
        self.assertGreater(len(item["base_image_prompt_for_gemini_or_codex"]), 50)
        self.assertGreater(len(item["video_motion_prompt_for_video_engine"]), 30)

    def test_generate_type_b_workout_pushup(self):
        item = generate_type_b_workout(self.persona, self.setting, "pushup")
        self.assertIn("Type B: Phone Setup & Reps (pushup)", item["asset_type"])
        self.assertIn("push-up position", item["base_image_prompt_for_gemini_or_codex"])
        self.assertIn("Kling AI", item["recommended_engine"])
        self.assertEqual(item["parameters"]["aspect_ratio"], "9:16")

    def test_generate_type_b_workout_squat(self):
        item = generate_type_b_workout(self.persona, self.setting, "squat")
        self.assertIn("Type B: Phone Setup & Reps (squat)", item["asset_type"])
        self.assertIn("squat", item["base_image_prompt_for_gemini_or_codex"])
        self.assertIn("squats", item["video_motion_prompt_for_video_engine"])

    def test_generate_type_c_reaction(self):
        item = generate_type_c_reaction(self.persona, self.setting, "pushup")
        self.assertIn("Type C: Fatigue & Screen Reaction", item["asset_type"])
        self.assertIn("Hailuo AI", item["recommended_engine"])
        self.assertIn("phone", item["base_image_prompt_for_gemini_or_codex"])

    def test_generate_matrix_all(self):
        matrix = generate_matrix("all", "pushup", count=2)
        # 2 counts * 3 types = 6 items
        self.assertEqual(len(matrix), 6)
        formatted = format_output(matrix)
        self.assertIn("TRAINING ARENA: AI UGC VIDEO GENERATION PROMPTS", formatted)
        self.assertIn("[6]", formatted)

    def test_generate_matrix_single_type(self):
        matrix = generate_matrix("hook", "pushup", count=3)
        self.assertEqual(len(matrix), 3)
        for item in matrix:
            self.assertIn("Type A: Hook", item["asset_type"])

if __name__ == "__main__":
    unittest.main()
