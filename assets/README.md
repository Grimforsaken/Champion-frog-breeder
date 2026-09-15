# Asset slots

The prototype runs without art by falling back to simple colors/labels. Add the approved art as WebP files using these exact paths and the game will load them automatically.

## First-person scenes

- `assets/scenes/lab.webp` — Home/Lab first-person background
- `assets/scenes/shop.webp` — Pet Shop first-person background
- `assets/home/table.webp` — empty wooden table used by the tank-management layer

## Top-down habitats

- `assets/habitats/backyard_puddle.webp` — starter habitat
- `assets/habitats/pond.webp` — first unlocked habitat

## Tank shells

- `assets/tanks/tank_small_01.webp`
- `assets/tanks/tank_small_02.webp`
- `assets/tanks/tank_small_03.webp`
- `assets/tanks/tank_small_04.webp`

Tank shells should have true alpha transparency outside the glass/frame.

## Starter tank backgrounds

- `assets/tank_backgrounds/rock_moss.webp`
- `assets/tank_backgrounds/tropical_vines.webp`
- `assets/tank_backgrounds/bark_moss.webp`

## Starter tank items

- `assets/tank_items/leaf_litter.webp`
- `assets/tank_items/broadleaf_plant.webp`
- `assets/tank_items/bark_bridge.webp`
- `assets/tank_items/rock_cluster.webp`
- `assets/tank_items/fern.webp`
- `assets/tank_items/moss_mound.webp`
- `assets/tank_items/bark_cave.webp`
- `assets/tank_items/water_dish.webp`

These are separate assets. Choosing a tank item will eventually auto-place it into a defined slot rather than requiring free placement.

## Frog life-cycle assets — first-person side view

- `assets/lifecycle/eggs_petri_dish.webp`
- `assets/lifecycle/tadpole_tank.webp`
- `assets/lifecycle/froglet_tank.webp`
- `assets/lifecycle/juvenile_tank.webp`

The juvenile/final pre-adult frog art should use neutral grayscale/mask-friendly shading so the runtime color system can apply the inherited hue.

## Adult frog masks

Regular frog:
- `assets/frogs/regular_side_mask.webp`
- `assets/frogs/regular_top_mask.webp`

Bullfrog:
- `assets/frogs/bullfrog_side_mask.webp`
- `assets/frogs/bullfrog_top_mask.webp`

The side assets are for Home/Lab tanks. The top assets are for habitat exploration. These should be neutral grayscale/transparent cutouts so the game can tint them using the 0–359 inherited color number while retaining highlights, shadows, and markings.

## Transparency

All modular tank items, tank shells, frogs, bugs, and life-cycle overlays should have true alpha transparency. Full-screen Lab, Shop, Backyard Puddle, and Pond images are opaque backgrounds.
