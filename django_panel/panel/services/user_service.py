from __future__ import annotations

from .json_repository import load_json


def get_users() -> list[dict]:
    return load_json("users")


def get_user_map() -> dict[str, dict]:
    return {user["id"]: user for user in get_users()}
