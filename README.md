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
- matching pocket-based layouts for PC withdrawal, deposit and item disposal
- up to 255 unique item stacks in both the Bag and item-storage PC
- quantities up to **x999** per item, with a wider native quantity selector
- centred native USE/TOSS, quantity, confirmation and party-target overlays
- two-line detail names and translatable item descriptions for longer languages

The first **All** pocket keeps every carried item in acquisition order, so the
screen remains familiar and compatible with the original flow. The other
pockets provide the organization used by more recent Pokémon games.

Item use, party targeting, battle turns, TMs/HMs, tossing, fishing, bicycles,
the Itemfinder, Escape Rope, the Poké Flute and scripted battle Bags still use
the engine's built-in controller.

Expanded inventory data is fully supported by Gen1Recomp's normal save files.
Exporting a save to the original Pokémon Red cartridge `.sav` format still
uses the hardware-era limits: 20 unique Bag items, 50 unique PC items and x99
per stack. Move or reduce overflow before exporting if you need that format.

## Controls

| Action | Control |
| --- | --- |
| Change pocket | Left / Right |
| Choose item | Up / Down, then A |
| Move item | Select, choose a new position, then Select or A |
| Close Bag | B |

The same pocket controls work in the PC item lists. The active operation
(Withdraw, Deposit or Toss), PC capacity and any confirmation message remain
visible in the responsive Bag-style frame.

## Translations

Pocket text and individual descriptions go through the engine's `strings`
catalog. A translation mod can override a description by its English source:

```lua
mod.content.strings:override(
  "Raises one POKéMON by one level.",
  "Your translated description.")
```

Long two-word item names wrap onto two centred lines in the detail card.
Single words only shorten when they cannot fit on one line.

## Development

From the Gen1Recomp repository root:

```sh
python3 tools/modkit.py validate modern_bag_ui --base auto
luajit mods/modern_bag_ui/tests/modern_bag_ui_test.lua
```

This package contains no ROM-derived assets. Pokémon and related names and
imagery are trademarks of their respective owners; this is an unofficial
fan-made mod.
