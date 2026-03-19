"""Supabase sync: push apply outcomes to the applypilot CRM table.

Called after each job result is committed to the local SQLite DB.
Fails silently — supabase errors are logged but never block the apply loop.
"""

from __future__ import annotations

import logging
import os
from datetime import datetime, timezone

from applypilot.database import get_connection

logger = logging.getLogger(__name__)

# Lazy-loaded supabase client (avoid import at module load time)
_supabase_client: object | None = None


def _get_client():
    """Return a Supabase client, or None if credentials are missing."""
    global _supabase_client
    if _supabase_client is None:
        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_KEY")
        if not url or not key:
            return None
        try:
            from supabase import create_client
            _supabase_client = create_client(url, key)
        except Exception as e:
            logger.warning("Failed to create Supabase client: %s", e)
            _supabase_client = False  # Don't retry
    if _supabase_client is False:
        return None
    return _supabase_client


def sync_job_to_supabase(url: str) -> bool:
    """Read a job from SQLite and upsert it to the applypilot Supabase table.

    Does nothing if SUPABASE_URL / SUPABASE_SERVICE_KEY are not set,
    or if the job has not yet been applied (no applied_at or apply_status).

    Returns True if synced successfully (or skipped gracefully), False on error.
    """
    conn = get_connection()
    row = conn.execute(
        "SELECT url, title, site, location, fit_score, score_reasoning, "
        "       applied_at, apply_status, apply_error, apply_attempts, "
        "       tailored_resume_path, cover_letter_path "
        "FROM jobs WHERE url = ?",
        (url,),
    ).fetchone()

    if not row:
        logger.warning("sync_job_to_supabase: job not found in SQLite: %s", url)
        return False

    # Only sync if an apply attempt was made
    if row["apply_status"] is None and row["applied_at"] is None:
        return True  # Not attempted yet — nothing to sync

    client = _get_client()
    if client is None:
        return True  # No credentials — skip

    now = datetime.now(timezone.utc).isoformat()

    # Normalize apply_status to match the applypilot table enum
    status = row["apply_status"] or "applied"
    if status == "in_progress":
        return True  # Still in progress — skip

    record = {
        "url": row["url"],
        "title": row["title"],
        "site": row["site"],
        "location": row["location"],
        "fit_score": row["fit_score"],
        "score_reasoning": row["score_reasoning"],
        "applied_at": row["applied_at"],
        "apply_status": status,
        "apply_error": row["apply_error"],
        "apply_attempts": row["apply_attempts"] or 0,
        "tailored_resume_path": row["tailored_resume_path"],
        "cover_letter_path": row["cover_letter_path"],
        "updated_at": now,
    }

    try:
        # Upsert — on_conflict allows re-syncing updated records
        client.table("applypilot").upsert(
            record,
            on_conflict="url",
        ).execute()
        logger.info("Synced to Supabase: %s [%s]", row["title"], status)
        return True
    except Exception as e:
        logger.warning("Supabase sync failed for %s: %s", url, e)
        return False
