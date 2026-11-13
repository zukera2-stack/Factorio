> **Latest successful verification:** [19 tests + Lua syntax + offline API guard](https://github.com/zukera2-stack/Factorio/actions/runs/43387339441), [preview artifact](https://github.com/zukera2-stack/Factorio/actions/runs/43387339441/artifacts/14018579988). Use the [generation brief and prompt pack](ART_BRIEF_35KV.md) to prepare actual source art; demo images are not final.

# ElectrifiedMainline — sprite generation and QA pipeline

**Branch:** feature/sprite-pipeline-0111. **Playable mod:** still 0.1.10, unchanged. **Target game:** Factorio 2.1.20; official API pages inspected were 2.1.24, not an exact match.

## Output and boundaries

The script produces 2x-ready transparent RGBA sprites for a pole, separate shadow and thin contact wire; SHA-256/alpha/geometry report; dark/light/checkerboard contact sheet; and a **review-only** Lua prototype snippet. Nothing is automatically included in the playable mod. The demonstration art is a deterministic **synthetic fixture**, not finished Factorio art.

Read the [API research](research/sprite-pipeline-0.1.11.md), [source manifest](../art/sprites/manifest.json), [pipeline code](../scripts/sprites/pipeline.py), [tests](../scripts/sprites/test_pipeline.py) and [CI workflow](../.github/workflows/sprite-pipeline.yml).

## Local use

Install Python 3.12 and Pillow, then from the repository root:

```bash
python -m pip install -r scripts/sprites/requirements.txt
python -m unittest discover -s scripts/sprites -p 'test_*.py' -v
python scripts/sprites/pipeline.py demo --out build/sprites/demo
python scripts/sprites/api_contract.py build/sprites/demo
```

Inspect build/sprites/demo/preview.png and report.json. The generated Lua prototype snippet is deliberately not loaded by data.lua.

## Prepare raw AI-generated art without cropping

The generator or artist may provide a larger RGBA PNG, not the exact target dimensions. First normalize it with the [preparation tool](../scripts/sprites/prepare.py). This extracts the complete alpha silhouette, preserves aspect ratio, aligns the pole base to the manifest anchor, resizes with antialiasing, adds transparent margins and then runs the same QA gates. It **rejects opaque backgrounds, vertical stripes and subjects touching the source image boundary** rather than inventing missing pixels or masking a screenshot. For example:

```bash
python scripts/sprites/prepare.py --input art/raw/pole.png --asset pole --output art/sprites/source/pole.png
python scripts/sprites/prepare.py --input art/raw/shadow.png --asset shadow --output art/sprites/source/shadow.png
python scripts/sprites/prepare.py --input art/raw/wire.png --asset wire --output art/sprites/source/wire.png
```

The tool does not remove backgrounds or generate new art with an AI model. Art generation remains a separate manual/connected-model stage; the pipeline ensures that exported artwork meets our technical contract.

## Production source workflow

Provide real **transparent RGBA PNG** source images in art/sprites/source/: pole.png (256x384), shadow.png (256x384), wire.png (512x48). No checkerboard or terrain baked into transparency. The manifest specifies alpha coverage, minimum transparent margins, pivot pixels and scale 0.5.

```bash
python scripts/sprites/pipeline.py production --source art/sprites/source --out build/sprites/review
```

Review the contact sheet on dark, light and checker backgrounds and at 100% and game-scale zoom. If art is approved, explicitly stage it into the mod graphics directory (this **does not** change any Lua prototypes):

```bash
python scripts/sprites/pipeline.py production --source art/sprites/source --out build/sprites/review --install --human-approved
```

Production mode refuses to fall back to synthetic demo images. The install switch requires both production mode and the human approval flag.

## Automated self-QA

| Gate | Failure detected |
|---|---|
| PNG signature, RGBA, exact pixel dimensions, <=16 MiB | Wrong format, JPEG, incorrect atlas |
| Alpha bounding box, transparent margin | Cropped geometry or opaque background |
| Alpha coverage and antialias edge count | Empty sprite, solid background, jagged cutout |
| Minimum distinct visible colours | Flat placeholders and simple stripe corruption |
| Repeating 2/4/8/16-pixel vertical pattern | Corrupt clipboard-like vertical stripe image |
| Opaque pixels near base anchor | Floating or misregistered pole and shadow |
| Calculated scale and shift in 32px/tile coordinates | Reproducible planned Factorio positioning |
| Lua 5.2 syntax, SHA-256, deterministic rerun | Syntactic invalidity or nondeterministic preprocessing |
| Offline Factorio API contract guard | Sprite paths, output hashes/dimensions, known RotatedSprite fields, source copper isolation invariants |

These checks cannot certify artistic quality, visual style match, real wire sag, perspective, in-game sprite atlas loading, correct render layers, or exact Factorio 2.1.20 compatibility.

## Required later integration and game tests

1. Replace synthetic fixture with approved source artwork; human review is mandatory.
2. In a **separate** gameplay change, set em-35kv-catenary-pole.pictures to the generated RotatedSprite layers and register the named wire SpritePrototype. Preserve all zero-copper-connection fields and 0.1.10 graph logic.
3. Confirm data-stage loading in Factorio 2.1.20 and compare sprites at normal zoom and alternate orientations; correct anchor, shadows and clipping.
4. Prototype textured wire spans using rendering.draw_sprite with orientation and x_scale/y_scale, verify 2/8/16-tile spans, corners, sag and clean removal. Retain working rendering.draw_line until verified.
5. Verify existing save, blueprint, robots, Ctrl+Z/Ctrl+Y, save/reload and UPS for 100+ supports. Record screenshots and factorio-current.log.
6. Only then publish a playable ZIP with new graphics. The CI sprite artifact is a **preview**, not a mod release.

The [offline API contract checker](../scripts/sprites/api_contract.py) compares generated Lua to a known reviewed schema, checks every output PNG SHA/dimension/path, and asserts existing pole isolation fields and the old line renderer remain unchanged. It labels 2.1.24 API references separately from target 2.1.20; it is **not** an engine schema validator or a substitute for Factorio data-stage loading.

## Verified CI evidence

[Sprite pipeline run #43387041605](https://github.com/zukera2-stack/Factorio/actions/runs/43387041605) passed 14 positive/negative unit tests, generated 3 RGBA PNGs, verified Lua 5.2 syntax, validated the offline Factorio sprite contract and uploaded [preview artifact 14018364046](https://github.com/zukera2-stack/Factorio/actions/runs/43387041605/artifacts/14018364046). [Docs run #43387041331](https://github.com/zukera2-stack/Factorio/actions/runs/43387041331) passed. The preview artifact is NOT a playable mod; no art has been loaded by Factorio.
