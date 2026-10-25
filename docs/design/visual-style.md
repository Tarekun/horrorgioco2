# Visual style

How the game looks: model and texture budgets, materials, lighting, post-processing and cutscenes. Story and tone live in [premise.md](premise.md).

## Target

**Early PS2 (2001–2003)**, with **Silent Hill 2** as the main reference. Models are more detailed than blocky PS1 ones but nowhere near PS3-era definition. Detail lives in textures, not geometry.

The aim is the game as you *remember* it on a CRT, not an emulator screenshot. So:

- the **assets** follow PS2-era budgets;
- **lighting** is modern by default: dynamic flashlight shadows, volumetric fog;
- an optional **retro filter** in the settings imitates the PS2's rendering limits for players who want it.

| Reference | What to take from it |
|---|---|
| Silent Hill 2 (2001) | Main reference: model detail, photo textures, fog, darkness, framing |
| Silent Hill 3 (2003) | Upper bound for character and texture detail |
| Fatal Frame / Project Zero (2001) | Dark interiors, grain, a frightening sense of what's off-screen |
| Metal Gear Solid 2 (2001) | Small photo-sourced textures that still read as real places |
| Silent Hill 2 remake (2024) | Only how modern lighting and fog sit over a scene. **Not** its asset detail. |

Out of bounds: PS1-style wobbly vertices and untextured flat shading below, and normal-mapped, physically based rendering (PBR) detail above.

## Models

Budgets are triangles at full detail. Shape the silhouette with geometry and put everything else in the texture.

| Asset | Triangles | Notes |
|---|---|---|
| Luca, Elena | 3,000–6,000 | The most detail goes to the head and hands |
| Surreal locals | 2,000–4,000 | |
| Standard monsters | 2,000–4,000 | |
| Bosses | up to 8,000 | |
| Small props | 50–500 | Bottles, signs, chairs |
| Hero props | up to 1,500 | Save spots, key items, the umbrella rows' repeated pieces |
| Whole scene on screen | about 50,000–100,000 | Guideline, not a hard limit |

- **Faceted curves.** Cylinders get 8–12 sides (an umbrella pole, a pipe); curves look faceted up close. No subdivision-smooth surfaces.
- **No bevels** for small detail. Use hard edges, smoothing groups and texture.
- **Hair** is a sculpted mesh or a few alpha-cutout cards, not strands.
- **Faces** use a simple rig: jaw, eyes, eyelids, plus a few blend shapes (blink, a handful of mouth shapes). No performance capture. The slight stiffness is part of the uncanniness.
- **Skeletons** have about 30–50 bones. Animation may be keyframed or motion-captured.

## Textures and materials

**Low-res and photo-sourced**: real photographs reduced to small textures, as in SH2 and MGS2.

- **Sources.** Prefer our own photos of real Romagna places (tiles, beach cabins, shop signs, posters, rusted railings, *colonia* walls), or CC0 libraries such as Poly Haven and ambientCG. Record every source and license in `assets/`, as #14 already requires.

  | Asset | Texture size |
  |---|---|
  | Luca, Elena | 512×512 body + 256×256 head |
  | Locals, monsters | 256–512 |
  | Props | 64–256 |
  | Environment tiles | 256, or 512 for large hero surfaces |

- **Texel density** for environments is about 128–200 px per meter. Close-ups are *supposed* to look soft.
- **Bake into the albedo.** Grime, stains, ambient occlusion and some lighting go straight into the colour texture, as PS2 games did. Vertex colours are allowed for tinting and extra shading.
- **Materials**: `StandardMaterial3D` with albedo (plus vertex colour), a constant roughness and metallic value per material, and emission for neon and screens.
  - **No normal, roughness or metallic maps.** They push the look toward the PS3 era.
- **Transparency**: alpha scissor (cutout) for foliage, fences, nets and hair cards. Alpha blending only for particles, fog cards and glass.
- **Import**: VRAM compressed, with mipmaps on.

## Lighting and atmosphere

Lighting is modern by default. It's tuned so darkness and fog do most of the work.

- **Darkness first.** Indoors, the flashlight is the main light source (#16, #17). Outdoors, a few sodium-vapour streetlights and neon signs in pools of black.
- **Baked static lighting.** Bake static environment lighting with `LightmapGI`. The baked, painterly falloff is part of the era's look, and it keeps dynamic lights cheap.
- **Few dynamic lights.** The flashlight is a shadowed spotlight; add a few others only where a scene needs them (a flickering sign, a lighter).
- **Fog is the signature.** Volumetric fog outdoors, from the sea (#17), plus depth fog to hide distance.
- **Effects off by default**: screen-space reflections, SDFGI and heavy SSAO, which all read as modern. Glow only for neon and emissive light sources.
- **Palette.** Washed-out, slightly desaturated colour, with:
  - sodium orange streetlights
  - cold grey-blue sea fog
  - the faded pink and cyan neon of the closed resort
  - rust and sun-bleached pastels

  Night and the unclear time after it (see [premise.md](premise.md)) use different grades of that palette.
- **Post-processing** (#18): film grain, vignette and a colour-grading lookup table. No motion blur and no depth of field during gameplay.
- **Aspect ratio**: widescreen 16:9. No 4:3 pillarboxing.

## Retro filter (optional setting)

A graphics setting, **off by default**, that imitates the PS2's rendering. It changes only the presentation: assets, lighting and gameplay stay exactly the same.

| | Default | Retro filter |
|---|---|---|
| 3D render resolution | native | 448 lines tall (e.g. 796×448 at 16:9), upscaled bilinearly |
| Anti-aliasing | on (MSAA or TAA) | off |
| Colour | full | reduced colour depth (about 5–6 bits per channel) with ordered dithering |
| Texture filtering | trilinear + 4× anisotropic | bilinear, no anisotropic |
| UI | native resolution | native resolution (stays sharp) |

- Use a low-resolution render target for the 3D scene, for example a `SubViewport` or the viewport's 3D scaling, plus a post shader for the dithering. It sits in the same post stack as #18.
- No scanlines, CRT curvature or fake interlacing. The goal is the rendering, not a TV gimmick.
- Check every scene with the filter on: fog, darkness and text on signs must still read at 448 lines.

## Cutscenes

**In-engine only**, with the same models as gameplay: no pre-rendered FMV and no higher-detail cutscene models.

- Emotion comes from framing, staging, body language, voice and sound, not facial detail.
- Use cinematic camera work. Letterbox bars are optional per scene.
- Cutscenes use the same lighting and post-processing as gameplay, and the retro filter if it's on.

## Impact on existing tasks

- **#14 Placeholder character**: Mixamo characters are often 10,000–30,000 triangles. That's fine for a placeholder, but prefer a lower-poly one, or decimate it towards the budget.
- **#17 Fog and darkness**: unchanged. It also needs to read well with the retro filter's low resolution.
- **#18 Post-processing**: also add the colour-grading lookup table. The retro filter is a separate piece of work (suggested: a new task under #15 Atmosphere), plus a toggle in the graphics settings (#35).
- **#37 Art pass**: follows these budgets and texture rules. Its tasks should include a photo-sourcing trip or texture library pass for Romagna textures.
