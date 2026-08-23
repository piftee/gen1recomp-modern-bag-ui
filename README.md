# Modern Bag UI

Modern Bag UI rebuilds the bare item list as a responsive, pocket-based Bag
while keeping Gen 1's font, palettes, sounds and item behavior.

**[Download the latest installable release](https://github.com/piftee/gen1recomp-modern-bag-ui/releases/latest)**

## What changes

- All plus five pockets: Items, Medicine, Poké Balls, TMs/HMs and Key Items
- two swappable skins: the current modern layout and a classic Pocket-style Bag
- left/right pocket navigation with a remembered cursor in every pocket
- a wider item list with selected-item details, quantities, money and capacity
- a source-faithful five-compartment backpack whose active pocket is highlighted
- responsive width that makes useful space on modern displays
- a portrait phone layout with more rows, stacked item details and readable controls
- safe item reordering inside both the All list and filtered pockets
- matching pocket-based layouts for PC withdrawal, deposit and item disposal
- up to 255 unique item stacks in both the Bag and item-storage PC
- quantities up to **x999** per item, with a wider native quantity selector
- centred native USE/TOSS, quantity, confirmation and party-target overlays
- overlay-safe sizing that keeps the responsive Bag surface on phones
- persistent PC transfer routes and distinct Withdraw, Deposit and Toss colours
- two-line detail names and translatable item descriptions for longer languages

The first **All** pocket keeps every carried item in acquisition order, so the
screen remains familiar and compatible with the original flow. The other
five pockets provide the organization used by more recent Pokémon games.
Battle-use items such as X Attack live in Items, keeping the five UI pockets
in a one-to-one relationship with the backpack's five highlighted regions.

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
| Change Bag skin | Options → Bag Skin → Modern / Pocket |
| Close Bag | B |

The **Pocket** skin uses a woven blue pocket selector, the reference's segmented
five-pocket backpack, a red active-pocket frame, clean white item sheet and a
bordered description panel. The highlighted backpack compartment follows the
selected pocket as you move left or right. On wide displays the selector is a
side rail; on tall phones it moves above the list so pocket labels and item
names retain the full readable width.
Changing **Bag Skin** applies immediately to both the Bag and PC item lists.

The same pocket controls work in the PC item lists. The active operation
(Withdraw, Deposit or Toss), PC capacity and any confirmation message remain
visible in the responsive Bag-style frame. The content area also shows the
route—**PC TO BAG**, **BAG TO PC** or **PC TO TRASH**—with a stable green,
yellow or red operation accent. Empty lists name the actual source instead of
falling back to the normal Bag pocket description.

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

The Pocket skin's backpack sprite is derived from the user-supplied visual
reference. Pokémon and related names and imagery are trademarks of their
respective owners; this is an unofficial fan-made mod.
