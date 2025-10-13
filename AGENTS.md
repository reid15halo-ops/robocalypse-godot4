# Repository Guidelines

## Project Structure & Module Organization
`project.godot` anchors the Godot 4 project. Gameplay scenes live under `scenes/`, while GDScript logic sits in `scripts/` with subfolders for `enemy_types/` and `map_mods/`. Art, audio, and other imports live in `assets/` and `sounds/`; keep generated files out of version control. Custom editor utilities (for tile map creation and asset splitting) are under `tools/`; review them before adding new pipelines.

## Build, Test, and Development Commands
Run the editor with `godot4 --path .` or open the project from Godot's project manager. For a quick playable build use `godot4 --headless --path . --run "Game"` to boot the main scene without the editor. Regenerate imports after changing source art with `godot4 --headless --path . --script tools/configure_imports.gd`. Python helpers in `tools/` can be executed via `python tools/asset_splitter.py --help` (activate `venv\Scripts\activate` first if you rely on the local virtualenv).

## Coding Style & Naming Conventions
Follow Godot standards: indent with 4 spaces, `class_name` and node scripts in PascalCase, member variables and signals in snake_case, and constants in ALL_CAPS. Prefer `@onready var` for node references and use typed GDScript for new code (`var health: int = 100`). Resource paths should remain relative (`res://scripts/...`). Keep UI strings centralized in the relevant manager to simplify localization.

## Testing Guidelines
Automated tests are not yet present; add GDUnit or native Godot test scenes under `scenes/tests/` when introducing complex systems. Smoke-test critical flows (ability activation, enemy spawns, map modifiers) by launching the main scene in headless mode and verifying logs. Document manual QA steps in `BUGFIXES.md` when you close defects so others can rerun them.

## Commit & Pull Request Guidelines
Write commits in the imperative mood (e.g., `Add drone cooldown clamp`) and keep them scoped to one feature or fix. Update `CRITICAL_FIXES_CHANGELOG.md` and `BUGFIXES.md` whenever you alter balancing or stability-sensitive logic. Pull requests should include a short summary, key test evidence (commands run or screenshots), and references to issue IDs where applicable. Highlight any tool scripts or import settings that contributors need to rerun after merging.

## Tooling & Environment Tips
Use the repository’s `venv` directory for Python-based asset automation to avoid polluting the global environment. Godot caches live in `.godot/`; clear it only if import glitches persist. For large binary assets, compress previews before committing to keep the repository lean.
