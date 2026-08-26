# Pocket Skin Design QA

- Source visual truth: `/var/folders/_f/5hxfvt8s7tnfcfx87lg2xcn00000gn/T/codex-clipboard-0cf0fffd-9c0e-4a0d-8fc6-8eee81b0c960.png`
- Implementation: `/tmp/modern-bag-ui-skins/classic_pocket_bag_reference.png`
- Pocket-change states: `/tmp/modern-bag-ui-skins/classic_pocket_bag_{medicine,balls,machines,key}.png`
- Combined comparison: `/tmp/modern-bag-ui-skins/classic-pocket-comparison.png`
- Focused sprite comparison: `/tmp/modern-bag-ui-skins/classic-pocket-bag-focused-comparison.png`
- Five-state strip: `/tmp/modern-bag-ui-skins/classic-pocket-five-state-strip.png`
- Source pixels: 1344 × 1160, normalized to 832 × 720 with aspect preserved and white side padding.
- Implementation pixels / viewport: 832 × 720.
- Runtime density: 166 × 144 logical UI surface at a 5× integer pixel scale; no fractional resampling.
- State: Bag → Items pocket → Pocket skin, Escape Rope selected, Red++ palette.

## Full-view comparison evidence

The combined comparison places the normalized reference on the left and the
rendered Pocket skin on the right. Both use the same major composition: black
title bar, blue textured left rail, green backpack card, black pocket label
with red frame, white five-row item sheet, red selection arrow, right-aligned
quantities and a full-width bordered description card.

The focused 720 × 240 crop compares the source and implementation bag cards at
large enough scale to inspect every compartment edge. The 1200 × 180 state
strip then holds the viewport fixed while showing Items, Medicine, Poké Balls,
TMs/HMs and Key Items in sequence. It verifies five distinct highlights rather
than five static screenshots of the same sprite.

## Findings

- No actionable P0/P1/P2 mismatches remain. The implementation now uses the
  reference backpack itself, retains all five visible compartment boundaries,
  and moves one highlight through those exact regions as the pocket changes.

## Required fidelity surfaces

- Fonts and typography: passed. The implementation retains the game's native
  pixel type system, uses the bundled Plain Pixel face for the smaller rail
  label, and mirrors the reference's uppercase header/item hierarchy,
  right-aligned counts and larger two-line description treatment.
- Spacing and layout rhythm: passed. Rail/list proportions, five visible rows,
  header height and lower description region follow the reference. Responsive
  screenshots also pass at 1280 × 720 and 480 × 960.
- Colors and visual tokens: passed. Purple title, woven blue rail, green bag,
  red active pocket/selection and black-on-white content are provided by
  existing four-shade game palettes.
- Image quality and asset fidelity: passed. The final 34 × 21 sprite is
  source-derived rather than procedurally approximated, is rendered at its
  native logical size with nearest filtering, and preserves all five original
  compartments without smoothing, glow, or transparency artifacts.
- Copy and content: passed. Live item names, quantities, descriptions, money,
  capacity and PC operation labels remain data-driven rather than copied from
  the reference screenshot.

## Interaction and responsive checks

- Options → Bag Options opens one dedicated settings page. It contains Bag
  Skin and, when Useful Bag is installed, its Fullscreen Bag toggle; both
  settings apply immediately and persist through their owning mod options.
  Kanto Reforged adds its Bag Give toggle to the same page.
- The active choice applies immediately to new Bag and PC item-list screens.
- Left/right switching walks Items → Medicine → Poké Balls → TMs/HMs → Key
  Items and moves the backpack highlight through five separate regions. The
  combined All view leaves every region neutral; native item actions remain
  controller-owned.
- Desktop, near-square, and portrait layouts render without clipping persistent
  controls or overflowing the UI surface.
- Kanto Reforged uses its own five-pocket controller beneath both skins.
  Berries, GIVE, reorder, cancel cleanup, TM/HM behavior and its 60-slot limit
  remain controller-owned rather than being reconstructed by the presentation.

## Comparison history

1. Initial pass: the narrow rail shortened `POCKET` and `ITEMS`; the backpack
   read too much like a bottle; the detail inset picked up a purple antialiased
   line. Result: blocked by P2 label legibility and P2 icon fidelity.
2. Fixes: used the full rail width for labels, widened active-label allowance,
   refined the four-shade backpack silhouette, and replaced the inset line
   with integer-aligned filled edges. Post-fix evidence is the implementation
   and combined comparison listed above.
3. User-feedback pass: the uppercase rail label still read too large and the
   backpack image remained static across pockets. Fixes: introduced compact
   title-case rail names in a smaller bundled pixel face, and connected the
   backpack's front-pocket emblem to the active category. Post-fix evidence is
   the earlier Items/Medicine screenshot pair.
4. User-feedback pass: the procedural backpack and small category badges still
   failed P1 asset fidelity and did not represent the source's five segmented
   compartments. Fixes: replaced the approximation with a native-size crop of
   the supplied sprite, segmented its five interior regions, mapped one real
   item category to each region, and folded battle enhancers into Items so the
   model remains one-to-one. Post-fix evidence is the refreshed full-view,
   focused comparison and five-state strip listed above.
   No actionable P0/P1/P2 findings remain.
5. Contrast pass: the first segmented version used light green for the active
   region. The requested black fill now follows the source's stronger selected
   state and remains distinct in all five compartment sizes. Post-fix evidence
   is the current focused comparison and five-state strip.
6. Mobile legibility pass: the 48-pixel portrait side rail left too little room
   for both its pocket label and translated item names. Tall layouts now move
   the bag and active-pocket frame into a full-width strip beneath the header;
   the item sheet uses all 160 logical pixels below it. Wide layouts retain the
   reference-like side rail.
7. Overlay and PC-operation pass: transparent overlays retain the owning Bag's
   responsive surface even when they declare a classic size, while visible
   touch controls are excluded from the usable portrait height. PC item views
   repeat a directional route in the content card and use stable operation
   colours and source-specific empty copy.

## Follow-up polish

- P3: the woven rail deliberately uses a more regular Game Boy checker than
  the denser reference texture so it stays stable at very small native sizes.

final result: passed
