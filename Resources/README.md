# Web SQLite snapshot

`WebPrompts.sqlite` is a consistent SQLite backup of
`../prompt_shortcut_tools/prisma/prompts.db`, captured on 2026-10-22 for local
iOS validation. It contains existing user content, not synthetic sample data.

- 19 prompts: 12 notes and 7 templates.
- 13 source tags, including unused tags.
- 7 referenced tag names have no source tag row; iOS recovers them during import.
- Every business-table field was compared with the source after export.
- Snapshot SHA-256: `934637c318de423b3723d78a33716db014e03816488b2d6f5544a22c5557f59a`.

Regenerate with `python3 Scripts/export_web_snapshot.py` from the project root.
This opens the web database read-only, validates the result, and atomically
replaces the resource. It never changes the original database. Only the SQLite
file is included in the app bundle; this README is not a build resource.

The app merges new source IDs once. Existing local records and edits survive;
deleted imported records are not resurrected. This is not live synchronization.
