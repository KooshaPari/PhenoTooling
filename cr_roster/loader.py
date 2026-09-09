"""Loader for the cr_roster provider catalog.

Public API:
    load_providers(validate_schema: bool = False) -> list[dict]

Raises:
    RosterError: when the YAML is missing, malformed, or fails schema validation.
"""
from __future__ import annotations

from pathlib import Path
from typing import Any

import json

import yaml

ROSTER_ROOT = Path(__file__).resolve().parent
PROVIDERS_YAML = ROSTER_ROOT / "providers.yaml"
SCHEMA_JSON = ROSTER_ROOT / "schema.json"


class RosterError(Exception):
    """Raised when the roster cannot be loaded or validated."""


def load_providers(validate_schema: bool = False) -> list[dict[str, Any]]:
    """Load and return the provider catalog as a list of dicts.

    Args:
        validate_schema: When True, validate the YAML against schema.json.

    Returns:
        Providers sorted by ascending ``priority`` (1 = highest).

    Raises:
        RosterError: if the file is missing, malformed, or fails validation.
    """
    if not PROVIDERS_YAML.exists():
        raise RosterError(
            f"providers.yaml not found at {PROVIDERS_YAML}. "
            "See docs/superpowers/specs/2026-09-09-automated-code-review-workflow-orchestration-design.md §3 SP1."
        )

    try:
        with PROVIDERS_YAML.open("r", encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
    except yaml.YAMLError as exc:
        raise RosterError(f"providers.yaml is malformed: {exc}") from exc

    if not isinstance(data, dict) or "providers" not in data:
        raise RosterError(
            "providers.yaml must be a mapping with a top-level 'providers' key"
        )

    providers = data["providers"]
    if not isinstance(providers, list):
        raise RosterError("'providers' must be a list")

    if validate_schema:
        _validate_against_schema(providers)

    providers.sort(key=lambda p: p.get("priority", 10_000))
    return providers


def _validate_against_schema(providers: list[dict[str, Any]]) -> None:
    """Validate the loaded providers against schema.json."""
    if not SCHEMA_JSON.exists():
        raise RosterError(
            f"schema.json not found at {SCHEMA_JSON}; cannot validate."
        )
    try:
        import jsonschema  # local import so the dep is optional for non-validating callers
    except ImportError as exc:
        raise RosterError(
            "jsonschema is not installed; install with `pip install jsonschema`"
        ) from exc

    with SCHEMA_JSON.open("r", encoding="utf-8") as fh:
        schema = json.load(fh)

    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors({"schema_version": 1, "providers": providers}), key=lambda e: e.path)
    if errors:
        msgs = [f"{'/'.join(map(str, e.path)) or '<root>'}: {e.message}" for e in errors]
        raise RosterError("schema validation failed:\n  - " + "\n  - ".join(msgs))
