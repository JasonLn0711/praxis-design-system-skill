#!/usr/bin/env python3
"""Independently parse skill metadata with a standard YAML parser."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
from typing import Any

import yaml


class UniqueKeyLoader(yaml.SafeLoader):
    """SafeLoader variant that rejects duplicate mapping keys."""


def construct_unique_mapping(
    loader: UniqueKeyLoader, node: yaml.nodes.MappingNode, deep: bool = False
) -> dict[Any, Any]:
    mapping: dict[Any, Any] = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise yaml.constructor.ConstructorError(
                "while constructing a mapping",
                node.start_mark,
                f"found duplicate key {key!r}",
                key_node.start_mark,
            )
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


UniqueKeyLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_unique_mapping
)


def load_yaml(text: str, source: Path) -> Any:
    try:
        return yaml.load(text, Loader=UniqueKeyLoader)
    except yaml.YAMLError as exc:
        raise ValueError(f"{source}: invalid YAML: {exc}") from exc


def read_frontmatter(path: Path) -> Any:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        raise ValueError(f"{path}: frontmatter must start on the first line")
    try:
        closing = lines.index("---", 1)
    except ValueError as exc:
        raise ValueError(f"{path}: missing closing frontmatter delimiter") from exc
    return load_yaml("\n".join(lines[1:closing]), path)


def require_mapping(value: Any, source: Path, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError(f"{source}: {label} must be a mapping")
    return value


def validate_skill(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        data = require_mapping(read_frontmatter(path), path, "frontmatter")
        for field in ("name", "description"):
            value = data.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{path}: {field} must be a non-empty string")
        if "metadata" in data and not isinstance(data["metadata"], dict):
            errors.append(f"{path}: metadata must be a mapping when present")
    except (OSError, ValueError) as exc:
        errors.append(str(exc))
    return errors


def validate_agent(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        data = require_mapping(load_yaml(path.read_text(encoding="utf-8"), path), path, "document")
        interface = require_mapping(data.get("interface"), path, "interface")
        for field in ("display_name", "short_description", "default_prompt"):
            value = interface.get(field)
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{path}: interface.{field} must be a non-empty string")
        policy = data.get("policy")
        if policy is not None:
            policy = require_mapping(policy, path, "policy")
            implicit = policy.get("allow_implicit_invocation")
            if implicit is not None and not isinstance(implicit, bool):
                errors.append(
                    f"{path}: policy.allow_implicit_invocation must be a boolean"
                )
    except (OSError, ValueError) as exc:
        errors.append(str(exc))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--repo-root", type=Path, default=Path(__file__).resolve().parents[1]
    )
    args = parser.parse_args()
    skills_root = args.repo_root.resolve() / "skills"
    errors: list[str] = []
    skill_files = sorted(skills_root.glob("*/SKILL.md"))
    if not skill_files:
        errors.append(f"{skills_root}: no skills found")
    for skill_file in skill_files:
        errors.extend(validate_skill(skill_file))
        agent_file = skill_file.parent / "agents" / "openai.yaml"
        if not agent_file.is_file():
            errors.append(f"{agent_file}: file not found")
        else:
            errors.extend(validate_agent(agent_file))

    if errors:
        print(f"Independent YAML validation failed with {len(errors)} error(s):")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        f"Independent YAML validation passed for {len(skill_files)} skills "
        f"with PyYAML {yaml.__version__}."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
