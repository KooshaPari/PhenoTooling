"""ProviderQueue: wraps cr_roster.load_providers() and answers "who's next?".

STUB — real implementation lands in Task 7 (P1 plan).
"""
from __future__ import annotations

from typing import Any, Iterable


class ProviderQueue:
    """STUB."""

    def __init__(self, providers: list[dict[str, Any]] | None = None) -> None:
        raise NotImplementedError

    def iter(self) -> Iterable[dict[str, Any]]:
        raise NotImplementedError

    def next(self, exhausted: set[str] | None = None) -> dict[str, Any] | None:
        raise NotImplementedError

    def all_ids(self) -> list[str]:
        raise NotImplementedError
