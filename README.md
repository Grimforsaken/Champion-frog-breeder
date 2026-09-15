# Champion Frog Breeder

An Android-focused frog catching, breeding, genetics, contest, and exploration game.

The current prototype is being built in **Godot 4**. Home/Lab and Pet Shop are first-person management scenes; wild habitats are strict top-down exploration scenes.

## Core daily loop

1. Every day begins at **Home/Lab** with frog upkeep.
2. From Home, the player can visit the **Pet Shop** or choose an unlocked habitat from the habitat dropdown.
3. From the Pet Shop, the player can return Home or leave directly for a habitat.
4. Once the player enters a habitat, the Pet Shop is unavailable for the rest of that day.
5. A habitat day runs **Day -> Evening -> Night**.
6. Each time period advances after **3 successful captures**. A failed capture makes that animal escape but does not consume one of the three capture slots.
7. The player can skip a time period or choose **Go Home** early.
8. Leaving a habitat starts the end-of-day sequence. The next day begins at Home with upkeep again.

Only one habitat can be visited per in-game day.

## Opening progression

- Start at the **Backyard Puddle**.
- Start with **no net**; the player catches frogs and bugs by hand using a timing-bar minigame.
- Frog carrying case holds **6 frogs**.
- Starter breeding tank supports **2 adult frogs**.
- Backyard Puddle bugs:
  - Cricket — evening/night
  - Worm — day/evening
- An early **blacklight flashlight** works during evening/night and helps identify fluorescent bugs and, later, fluorescent frogs.
- Basic feeder bugs can be bought from the Pet Shop so frogs can always be fed.
- Frogs grow daily and require daily food.
- Selling frogs funds nets, field gear, additional tanks, and increasingly advanced Home/Lab equipment.
- The **Pond** unlocks shortly afterward through shopkeeper progression and introduces new wildlife including bullfrogs.

## Current playable prototype

The `prototype-core` branch contains the first working systems:

- Home/Lab, Pet Shop, and habitat navigation
- mandatory daily frog feeding before leaving for a habitat
- Day / Evening / Night progression
- multiple visible capture opportunities
- hand-catching timing minigame
- small-net upgrade that makes captures easier
- 6-frog field case
- Backyard Puddle bug schedules
- Pond wildlife pool
- blacklight toggle during evening/night
- fluorescent catches
- buying feeder bugs, net, blacklight, bug-container upgrade, and tanks
- selling frogs
- starter breeding tank and tank thumbnails
- moving frogs between case and selected tank
- breeding and egg clutch creation
- egg -> tadpole -> froglet -> juvenile -> adult daily growth
- inherited 0–359 hue-number color system
- Pond unlock through early progression

The game will run with placeholder colors/labels if art has not yet been imported. Approved art paths are documented in `assets/README.md`.

## Genetics

Frog appearance and performance are data-driven and inherited. See `docs/GENETICS.md` for the base color-number system and breeding rules.

## Run locally

Open the repository in Godot 4.3+ and run the project. The main scene is `src/Main.tscn`.
