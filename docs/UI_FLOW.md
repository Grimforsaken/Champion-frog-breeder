# UI and Daily Flow

## Viewpoints

- Home / Lab: first-person room view.
- Pet Shop: first-person shop-counter view.
- Wild habitats: strict top-down view for searching and capture opportunities.

## Daily flow

Each in-game day begins at Home / Lab with frog upkeep.

1. Feed and inspect frogs at Home / Lab.
2. From the top navigation, either visit the Pet Shop or choose an unlocked habitat from the habitat dropdown.
3. From the Pet Shop, the player may return Home or leave directly for a habitat.
4. Entering a habitat locks the Pet Shop for the rest of that day.
5. Habitats run through Day -> Evening -> Night.
6. The player gets up to 3 successful captures per time period.
7. The player may skip a time period at any time.
8. The player may leave the habitat and Go Home early.
9. Leaving a habitat immediately starts the end-of-day sequence.
10. Growth is processed, the next day begins at Home, and frog upkeep is required again.

## Habitat searching

The habitat image remains visible as the play field. Multiple possible frogs and bugs can be visible at the same time. The player chooses which target to attempt rather than receiving a forced encounter.

Selecting a target opens the capture timing minigame. The player begins the game catching by hand. The first net upgrade slows the timing marker and widens the success zone. Later catching gear will continue this progression until ordinary targets can eventually be auto-captured.

The Backyard Puddle begins with:
- Worm: Day and Evening.
- Cricket: Evening and Night.

The blacklight flashlight is usable in Evening and Night and helps identify fluorescent creatures. This makes fluorescent worms harder to deliberately find because they only overlap with blacklight use during Evening.

The Pond is an early unlock and includes bullfrogs plus new bug species.

## Home tank interaction

The Home / Lab tank-management view is modular.

Layer order:
1. Lab room background.
2. Empty wooden table / work surface.
3. Selected tank background panel.
4. Auto-placed tank items.
5. Side-view frog assets.
6. Transparent tank shell / glass frame.
7. UI controls.

The currently viewed tank is shown on the table. Other owned tanks appear as thumbnails along the bottom.

Starter tank items are modular assets with predefined placement regions. Selecting an item from storage automatically places it into the active tank; there is no freeform pixel placement requirement.

Tank items in the active tank can be dragged onto another tank thumbnail to transfer them. They can also be dragged to the Storage thumbnail to remove them from the active tank for later use.

Starter backgrounds are selectable independently from tank items.

## Frog views and color system

- Home / Lab adult frogs use side-view transparent grayscale masks.
- Habitat frogs use top-down transparent grayscale masks.
- The inherited 0-359 hue number is applied at runtime by shader so one frog mask can display many genetic colors.
- Fluorescence remains a separate trait layered on top of the base hue.

Early life stages are shown from the side in the Home / Lab nursery:
- Eggs in a petri dish.
- Tadpole in a small tank.
- Froglet in a small tank.
- Juvenile / final pre-adult stage using neutral mask-friendly art once visible body color matters.
