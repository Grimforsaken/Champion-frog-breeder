# Frog Genetics — Color System

## Base color as a number

Each frog stores its base body color as a hue number on a circular 0–359 scale.

Example reference points:

- 0 = red
- 30 = orange
- 60 = yellow
- 120 = green
- 180 = cyan
- 240 = blue
- 300 = magenta
- 359 wraps back to red

The exact displayed color comes from that numeric hue value. Saturation and brightness can be handled as separate inherited/development traits later, but the core breeding color uses the hue number.

## Breeding rule

When two frogs breed, the offspring receives a random hue between the parents' hue values.

The system treats hue as a circle and chooses the shorter route around the color wheel. This prevents incorrect crosses near the 0/359 boundary.

Examples:

- Yellow parent 60 + green parent 120 -> offspring hue is randomly selected from 60 through 120.
- Green parent 120 + blue parent 240 -> offspring hue is randomly selected from 120 through 240.
- Parent 350 + parent 10 -> offspring is selected across the red boundary (350..359 or 0..10), not through the entire rest of the spectrum.

If both parents have the same hue, normal offspring use that same hue unless another genetic effect or mutation changes it.

## Rare color traits

Fluorescence is a separate genetic trait layered on top of the base hue. A fluorescent frog can therefore still have any normal numeric base color.

Other later effects such as iridescence, metallic sheen, pattern coloration, albinism, melanism, or mutation-based appearance changes should also remain separate from the base hue number unless a future design explicitly changes this rule.

## Why this system is used

This makes offspring colors continuous instead of forcing frogs into a small list of preset colors. Selective breeding can gradually move a bloodline toward a desired color, while rare traits and bug-induced mutations can modify how that base color is displayed.
