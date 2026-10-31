# Web Library Import

Approved scope: import the existing web SQLite snapshot into PromptMaster without
changing the web database or overwriting existing iOS records. Show all tags,
multi-select with OR semantics, search, type-specific lists, and favorites.

1. [x] Bundle a read-only business-data snapshot and a repeatable export script.
2. [x] Migrate SQLite to v2 and import transactionally with source row receipts.
   Preserve content, dates, metadata, favorites, and variables; create missing
   referenced tags; map Tailwind colors. Reopening must not duplicate or restore
   deleted imported records. Test rollback, ID collisions, and existing v1 data.
3. [x] Share filtering and list UI between home and favorites. Use native system
   typography, wrapping checkbox tags, 44pt targets, and separate note/template
   sections. Retain the existing wordmark and bottom navigation order.
4. [x] Verify imported counts/fields, OR + type + query + favorite filtering,
   template rendering, CRUD persistence, and UI interaction. Review simulator
   screenshots at regular/large text and small/large phone sizes. See
   ../validation/2026-10-22-web-library-import.md for evidence and limitations.

Source: ../prompt_shortcut_tools/prisma/prompts.db (opened read-only).
Destination: Application Support/PromptKit/PromptKit.sqlite.
