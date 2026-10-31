"""Export a consistent read-only SQLite snapshot for the iOS resource bundle."""

import argparse
import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile


def export_snapshot(source: Path, output: Path) -> dict:
    if source.resolve() == output.resolve():
        raise ValueError("Source and destination must be different files")
    output.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True) as original:
        with tempfile.NamedTemporaryFile(dir=output.parent, suffix=".sqlite", delete=False) as temp:
            temporary_path = Path(temp.name)
        try:
            with sqlite3.connect(temporary_path) as snapshot:
                original.backup(snapshot)
                snapshot.execute("PRAGMA journal_mode=DELETE")
                if snapshot.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                    raise ValueError("SQLite snapshot integrity check failed")
                prompts = snapshot.execute("SELECT isTemplate, tags, templateVars FROM Prompt").fetchall()
                tags = snapshot.execute("SELECT name FROM Tag").fetchall()
                tag_names = {row[0] for row in tags}
                referenced = set()
                for _, encoded_tags, variables in prompts:
                    names = json.loads(encoded_tags)
                    if not isinstance(names, list) or not all(isinstance(name, str) for name in names):
                        raise ValueError("Prompt tags must be a JSON string array")
                    referenced.update(names)
                    if variables is not None:
                        decoded = json.loads(variables)
                        if not isinstance(decoded, list) or not all(isinstance(name, str) for name in decoded):
                            raise ValueError("Template variables must be a JSON string array")
                summary = {
                    "prompts": len(prompts),
                    "notes": sum(not row[0] for row in prompts),
                    "templates": sum(bool(row[0]) for row in prompts),
                    "source_tags": len(tags),
                    "recovered_tags": sorted(referenced - tag_names),
                }
            temporary_path.replace(output)
        finally:
            temporary_path.unlink(missing_ok=True)
    summary["snapshot_sha256"] = hashlib.sha256(output.read_bytes()).hexdigest()
    return summary


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=root.parent / "prompt_shortcut_tools/prisma/prompts.db")
    parser.add_argument("--output", type=Path, default=root / "Resources/WebPrompts.sqlite")
    args = parser.parse_args()
    print(json.dumps(export_snapshot(args.source, args.output), ensure_ascii=False, indent=2))
