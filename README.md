# SoD Rune Enforcer

A World of Warcraft Season of Discovery (SoD) addon for raid leaders to ensure all members are using runes appropriate for the current phase of the game.

## Features
- **Phase Enforcement:** Set the current raid phase (Phases 1 through 8) to enforce power caps (e.g., Phase 1 for Blackfathom Deeps).
- **Interactive Grid UI**: A clean, draggable two-panel interface:
  - **Left Control Panel**: Select the active phase, trigger group scans, and clear the scan cache.
  - **Right Raid Monitor**: Displays group members organized into standard raid columns (`G1` - `G8`), matching your in-game layout.
- **Color-Coded Statuses**:
  - **Grey**: Player is unscanned or out of range.
  - **Green**: Player is fully compliant.
  - **Red**: Player has a future-phase rune equipped (violating).
- **Hover Tooltips**: Mouse over any player's cell to see their name (class-colored) and a detailed list of equipped runes, their native phases, and compliance statuses.
- **Manual Click Inspect**: Left-click any player's cell to prioritize and scan them directly.
- **Self-Checking warnings**: Pulsing red glows on your Character Sheet (C) and warning highlights in the Engraving UI for out-of-compliance runes.
- **Slash Commands**: Quick and easy shortcuts.

## Usage
- `/sre` or `/sre ui` - Toggles the graphical control panel.
- `/sre phase [1-8]` - Manually sets the enforcement level:
    - **Phase 1 (Lv 25):** Chest, Hands, Legs.
    - **Phase 2 (Lv 40):** Adds Waist, Feet.
    - **Phase 3 (Lv 50):** Adds Head, Wrist.
    - **Phase 4+ (Lv 60):** Adds Cloak, Rings.
- `/sre check` - Triggers a raid-wide inspection queue.
- `/sre debug` - Prints a detailed status of your own character's runes and compliance in chat.

## Local Credentials and Publishing
If you are developing or maintaining this addon, you can publish releases to CurseForge:
1. Create a `.env` file in the root folder (this is already ignored by git):
   ```env
   CURSEFORGE_PROJECT_ID=1570580
   CURSEFORGE_API_TOKEN=YOUR_API_TOKEN_HERE
   ```
2. Build the staging release zip:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\release.ps1 -Version 1.4.1
   ```
3. Upload to CurseForge using the API script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\publish-curseforge.ps1
   ```

## Installation
1. Copy the `SoDRuneEnforcer` folder to your `World of Warcraft/_classic_era_/Interface/AddOns` directory.
2. Restart the game or type `/reload`.
