# Modern Bag UI

Modern Bag UI rebuilds the bare item list as a responsive, pocket-based Bag
while keeping Gen 1's font, palettes, sounds and item behavior.

**[Download the latest installable release](https://github.com/piftee/gen1recomp-modern-bag-ui/releases/latest)**

## What changes

- seven pockets: All, Items, Medicine, Poké Balls, Battle, TMs/HMs and Key Items
- left/right pocket navigation with a remembered cursor in every pocket
- a wider item list with selected-item details, quantities, money and capacity
- pocket-specific illustrations drawn from the Game Boy's four visual shades
- responsive width that makes useful space on modern displays
- a portrait phone layout with more rows, stacked item details and readable controls
- safe item reordering inside both the All list and filtered pockets

The first **All** pocket keeps every carried item in acquisition order, so the
screen remains familiar and compatible with the original flow. The other
pockets provide the organization used by more recent Pokémon games.

The mod changes presentation only. Item use, party targeting, battle turns,
TMs/HMs, tossing, fishing, bicycles, the Itemfinder, Escape Rope, the Poké
Flute and scripted battle Bags still use the engine's built-in controller.

## Controls

| Action | Control |
| --- | --- |
| Change pocket | Left / Right |
| Choose item | Up / Down, then A |
| Move item | Select, choose a new position, then Select or A |
| Close Bag | B |

## Development

From the Gen1Recomp repository root:

```sh
python3 tools/modkit.py validate modern_bag_ui --base auto
luajit mods/modern_bag_ui/tests/modern_bag_ui_test.lua
```

This package contains no ROM-derived assets. Pokémon and related names and
imagery are trademarks of their respective owners; this is an unofficial
fan-made mod.
