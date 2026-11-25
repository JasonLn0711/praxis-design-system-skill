from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "validate-yaml.py"
SPEC = importlib.util.spec_from_file_location("validate_yaml", SCRIPT)
assert SPEC and SPEC.loader
validate_yaml = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validate_yaml)


class YamlValidationTests(unittest.TestCase):
    def test_plain_colon_is_rejected_but_quoted_and_block_scalars_pass(self) -> None:
        with self.assertRaises(ValueError):
            validate_yaml.load_yaml(
                "name: frontend-code-architecture\n"
                "description: Use when architecture: component boundaries\n",
                Path("SKILL.md"),
            )
        quoted = validate_yaml.load_yaml(
            'name: frontend-code-architecture\n'
            'description: "Use when architecture: component boundaries"\n',
            Path("SKILL.md"),
        )
        block = validate_yaml.load_yaml(
            "name: frontend-code-architecture\n"
            "description: >-\n"
            "  Use when architecture: component boundaries\n",
            Path("SKILL.md"),
        )
        self.assertIsInstance(quoted["description"], str)
        self.assertIsInstance(block["description"], str)

    def test_malformed_yaml_and_duplicate_keys_are_rejected(self) -> None:
        samples = (
            'name: "unterminated\n',
            "name: ok\n description: bad-indent\n",
            "name: one\nname: two\n",
        )
        for sample in samples:
            with self.subTest(sample=sample), self.assertRaises(ValueError):
                validate_yaml.load_yaml(sample, Path("test.yaml"))

    def test_skill_required_fields_must_be_strings(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "SKILL.md"
            path.write_text("---\nname: 7\ndescription: false\n---\n", encoding="utf-8")
            errors = validate_yaml.validate_skill(path)
        self.assertTrue(any("name must be" in item for item in errors))
        self.assertTrue(any("description must be" in item for item in errors))

    def test_policy_boolean_is_not_confused_with_string(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "openai.yaml"
            base = (
                "interface:\n"
                '  display_name: "Example Skill"\n'
                '  short_description: "Example description long enough"\n'
                '  default_prompt: "Use $example to do the task."\n'
            )
            path.write_text(
                base + "policy:\n  allow_implicit_invocation: false\n",
                encoding="utf-8",
            )
            self.assertEqual([], validate_yaml.validate_agent(path))
            path.write_text(
                base + 'policy:\n  allow_implicit_invocation: "false"\n',
                encoding="utf-8",
            )
            errors = validate_yaml.validate_agent(path)
        self.assertTrue(any("must be a boolean" in item for item in errors))


if __name__ == "__main__":
    unittest.main()
