"""Router: composes ProviderQueue + QuotaStore to answer "who's next?".

STUB — real implementation lands in Task 9 (P1 plan).
"""
from __future__ import annotations

from typing import Any


class RouterError(Exception):
    """Raised for router-level misuse (e.g. no providers configured)."""


class Router:
    """STUB."""

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        raise NotImplementedError

    def pick(self) -> dict[str, Any] | None:
        raise NotImplementedError

    def status(self) -> dict[str, Any]:
        raise NotImplementedError
