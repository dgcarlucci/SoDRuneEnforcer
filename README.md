# SoD Rune Enforcer

A World of Warcraft Season of Discovery (SoD) addon for raid leaders to ensure all members are using runes appropriate for the current phase of the game.

## Features
- **Official Phase Enforcement:** Set the current raid phase (Phases 1 through 8) to enforce power caps for specific raids (e.g., Phase 1 for Blackfathom Deeps).
- **Raid-wide Scanning:** Inspect all raid members with one click to detect runes introduced in future phases.
- **Proactive Self-Checking:** Instantly alerts you if you equip a rune that is out of compliance with the currently set phase.
- **Character Pane Highlights:** Provides a pulsing red glow on your Character Sheet (C) for any equipment slots containing invalid runes.
- **Quick-Access UI:** A draggable control panel for easy phase switching and scanning.

## Usage
- `/sre ui` - Toggles the graphical control panel.
- `/sre phase [1-8]` - Manually sets the enforcement level:
    - **Phase 1 (Lv 25):** Only Phase 1 runes allowed.
    - **Phase 2 (Lv 40):** Phase 1 & 2 runes allowed.
    - **Phase 3 (Lv 50):** Phase 1, 2, & 3 runes allowed.
    - **Phase 4-8 (Lv 60):** Level 60 content runes (Back, Rings, etc.) allowed based on the selected phase.
- `/sre check` - Triggers a raid-wide inspection. The addon will report any player using a rune that was introduced in a phase higher than the one currently set.

## How it Works
The addon maintains a database of every rune and the specific phase it was "discovered" or introduced. Unlike simple level checks, this prevents players from using powerful Level 60 utility or power-creep runes in early-game raids like BFD or Gnomer, even if those runes occupy slots like "Chest" or "Hands."

## Installation
1. Copy the `SoDRuneEnforcer` folder to your `World of Warcraft/_classic_era_/Interface/AddOns` directory.
2. Restart the game or type `/reload`.

## Notes
- To inspect other players, you must be within inspection range.
- The addon uses tooltip scanning to identify "Engraved" runes on gear.
