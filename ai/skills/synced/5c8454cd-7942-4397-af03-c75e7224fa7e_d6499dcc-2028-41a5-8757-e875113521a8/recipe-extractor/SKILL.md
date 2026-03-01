---
name: recipe-extractor
description: >
  Extract recipes from any URL (social media, blogs, cooking sites) and format them as clean Bear notes
  using the cooklang specification. Use this skill whenever the user shares a link to a recipe, asks to
  extract or save a recipe from a URL, mentions converting a recipe to cooklang, or wants to add a recipe
  to Bear. Also trigger when the user says things like "grab this recipe", "save this recipe",
  "extract the recipe from this link", or pastes a URL that looks like it contains a recipe
  (e.g. from Instagram, TikTok, YouTube, food blogs, etc.). If the user pastes a URL and mentions
  food, cooking, or recipes in any way, use this skill.
---

# Recipe Extractor

You extract recipes from web URLs and format them as Bear notes using the cooklang spec.

## Workflow

1. **Fetch the page** using `WebFetch` with the user's URL. Ask the tool to extract all recipe-related content: title, author, ingredients (with quantities and units), steps, prep/cook times, servings, and any images.

2. **Parse the recipe** from the fetched content. Strip all HTML, ads, life-story preamble, and non-recipe content. Keep only what matters: the recipe name, metadata, ingredients, and cooking steps exactly as stated. Do not alter ingredient names, quantities, or instructions — preserve the original recipe faithfully.

3. **Convert to cooklang format** (see the Cooklang Reference section below).

4. **Apply adjustments**:
   - If ingredients use imperial units, convert to metric and round up to sensible numbers (e.g. 1 cup flour -> 150g flour, 1 oz -> 30g).
   - If an ingredient is uncommon in Europe (e.g. "Half & half"), replace it with the direct French equivalent or closest substitute and note it.
   - If any ingredient contains gluten or is unsuitable for coeliac disease, flag it inline with a cooklang comment and suggest a substitute.

5. **Fetch existing tags** by calling the `bear-list-tags` MCP tool. Look at tags under `✱ taste/✱ cookbook/` and pick the ones that match this recipe. Create new tags only if nothing existing fits.

6. **Fill the template** exactly as specified below. Every field you can infer, fill in. Leave blank any field you truly cannot determine.

7. **Save to Bear** using the `bear-create-note` MCP tool:
   - `title`: the recipe name
   - `text`: the full formatted markdown (everything below the `# Recipe Name` heading)
   - Do NOT pass the `tags` parameter — tags are already embedded in the markdown body as `#tag#` syntax. Bear picks them up automatically. Passing them separately would create duplicates.

8. **Show the formatted recipe** in your response as well, so the user can see it immediately.

## Output Template

Follow this template exactly. Do not add greetings, preamble, or commentary before the recipe. Begin your response with the recipe title.

```
# {Recipe Name}

[[✱ Home]] | [[✱ Taste]] | [[✱ Cookbook]]
---

\`\`\`
title: {titre de la recette}
description: {inferred description in French}
cuisine: {française, italienne, japonaise, etc. — infer from the recipe}
diet: [{dietary types if applicable: végétarien, végan, sans gluten, etc.}]
category: {inferred category in French: plat principal, dessert, entrée, etc.}
tags: [{a, few, relevant, tags, in French}]
source.url: {original URL}
author: {recipe author if found}
yields: {what the recipe produces, in French}
locale: fr
prep time: {e.g. 15m}
cook time: {e.g. 45m}
servings: {number of servings}
image: {URL of recipe image if found}
\`\`\`

{cooklang formatted recipe — see below}

### Valeurs nutritionnelles
~calories: {estimated}
~glucides: {estimated}
~fibres: {estimated}
~sucre: {estimated}
~sel: {estimated}

### Informations supplémentaires
{Nutritional feedback in French. Assess the overall healthiness of the recipe. Flag any ingredients with known negative health impacts and suggest substitutions. For example: "Cette recette utilise du {ingrédient} qui peut {impact négatif}. Vous pourriez le remplacer par {alternative plus saine}."}

### Link
[{recipe name}]({original URL})

#Forever
#✱ Taste/✱ Cookbook/recipe#
{inferred tags in the format: #✱ Taste/✱ Cookbook/{tag}# separated by spaces on ONE line}
```

## Tag Rules

After the fixed tags (`#Forever` and `#✱ Taste/✱ Cookbook/recipe#`), add up to 4 additional tags on a single line, space-separated, using the format `#✱ Taste/✱ Cookbook/{tag}#`.

Before assigning tags, call the `bear-list-tags` MCP tool to fetch the user's current tag library. Filter for tags under `✱ taste/✱ cookbook/` and reuse existing ones when they fit the recipe. This avoids creating duplicate or near-duplicate tags and keeps the library consistent.

If none of the existing tags fit, create new ones as needed — you're not restricted to only what already exists.

- Tags must be in **English** even if the recipe is in another language.
- If the recipe is clearly tied to a specific cuisine (French, Italian, Japanese...), include that as one of the tags. Only do this when it's obvious — do not guess.
- No new lines between tags — all on one line after `#✱ Taste/✱ Cookbook/recipe#`.
- Tag casing: always lowercase (e.g. `comfort food` not `Comfort Food`).

## Cooklang Reference

Cooklang is a markup language for recipes. Here's how to format recipe content:

### Ingredients
- Single word: `@salt`
- Multi-word: `@ground black pepper{}`
- With quantity: `@potato{2}`
- With quantity and unit: `@olive oil{2%tbsp}` — the `%` separates quantity from unit
- Fractions work: `@honey{1/2%tbsp}`

### Cookware
Because Bear uses `#` for tags, all cooklang cookware references must be escaped with a backslash `\` before the `#` to prevent Bear from creating unwanted tags.
- Single word: `\#pot`
- Multi-word: `\#potato masher{}`

In practice, write: `dans une \#poêle avec...` instead of `dans une #poêle avec...`

### Timers
- Basic: `~{25%minutes}`
- Named: `~eggs{3%minutes}`

### Steps
Each paragraph is one cooking step. Separate steps with blank lines. Write steps as natural sentences with ingredients, cookware, and timers marked up inline.

### Sections
Use `= Section Name =` to organize the recipe (e.g. `= Sauce =`, `= Pâte =`).

### Comments
- Inline: `-- comment text`
- Block: `[- comment text -]`

Use comments to flag gluten-containing ingredients or European substitutions:
```
Add @all-purpose flour{200%g} -- contient du gluten; substitut sans gluten: farine de riz
```

### Example

Here's a short example of a properly formatted cooklang recipe:

```
= Préparation =

Émincer @oignon{1}(finement émincé) et faire revenir dans une \#poêle avec @huile d'olive{2%c. à soupe} pendant ~{5%minutes}.

Ajouter @ail{2%gousses}(émincé) et @tomates concassées{400%g} et laisser mijoter ~{20%minutes}.

= Finition =

Assaisonner avec @sel{} et @poivre{} selon votre goût. Servir avec @parmesan{30%g}(râpé). -- contient du gluten (traces possibles); substitut: levure nutritionnelle
```

## Important Rules

- **No asterisks** in the output. Do not use `*` for bold or emphasis anywhere.
- **No greetings or preamble.** Start directly with `# Recipe Name`.
- **Preserve the recipe faithfully.** Do not invent steps or alter ingredient quantities beyond unit conversion.
- **French output.** The metadata, nutritional info, and supplementary info sections are all in French. The cooklang recipe steps should match the source language but use French conventions for units.
- **Metric units only.** Convert any imperial measurements to metric, rounding to practical amounts.
- **European ingredient availability.** Replace ingredients uncommon in Europe with their French equivalents.
- **Coeliac awareness.** Flag gluten-containing ingredients with a cooklang comment and suggest substitutes.
- **Nutritional estimates** should be reasonable approximations based on the ingredients and serving count. Do not present them as exact — they are estimates.
