from __future__ import annotations

import logging
from typing import Any, Dict, Optional

from .supabase_client import get_supabase_client

logger = logging.getLogger(__name__)


def log_event(
    event_name: str,
    *,
    request=None,
    user_id: Optional[str] = None,
    hospital_id: Optional[str] = None,
    properties: Optional[Dict[str, Any]] = None,
) -> None:
    """
    Writes a lightweight audit/telemetry event to Supabase.
    """

    try:
        supabase = get_supabase_client()
        session_user = None
        session_hospital = None

        if request is not None:
            session_user = request.session.get("user_id")
            session_hospital = request.session.get("hospital_id")

        payload = {
            "event_name": event_name,
            "user_id": user_id or session_user,
            "hospital_id": hospital_id or session_hospital,
            "event_props": properties or {},
        }
        supabase.table("app_events").insert(payload).execute()
    except Exception as exc:
        logger.warning("Telemetry event '%s' could not be stored: %s", event_name, exc)


