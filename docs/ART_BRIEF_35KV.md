# 35 kV sprite art generation brief — 0.1.11-dev

Use this to generate ORIGINAL source artwork. It is not a game sprite package, and no copyrighted Factorio asset or third-party mod art may be traced/copied. The game-art direction is readable industrial isometric machinery with hand-painted metal, visible fasteners, believable porcelain insulators, restrained weathering, directional light and high silhouette contrast.

## A. Contact support / pole (portrait)

Generate one isolated industrial railway catenary support for a top-down isometric factory-building game: tall grey galvanized steel lattice mast with triangular bracing, ONE rightward cantilever arm forming a distinct Cyrillic Г / L silhouette, a diagonal support brace below the arm, and small brown ceramic insulators, narrow contact wire attachment points, bolts and mild wear, compact yellow-black hazard-striped foundation. Three-quarter/isometric view consistent with industrial game sprites, crisp painted texture, clean silhouette, visible full base and top, balanced highlights and dark outlines. **No T-shaped symmetrical crossbar, no double-sided gantry, no rails, no train, no wires spanning off canvas, no landscape, no floor, no text or logo. Transparent RGBA background.** Full object must have generous margin.

Output ideally portrait 1024x1536 RGBA, then use prepare.py to fit into 256x384 2x sprite with mast-foot anchor (75,354), scale 0.5. Do not assume the image model obeys exact dimensions or real alpha; inspect first.

## B. Separate ground shadow

Generate only the soft semi-transparent ground shadow cast by the same mast, as an isolated shadow mask on transparent RGBA. No physical pole, no ground colour, no checkerboard. Keep the shadow close to the origin with a short directional extension. Prepare as 256x384; mast-foot anchor (75,354). Shadow is a separate RotatedSprite layer with draw_as_shadow=true, not baked into the pole image.

## C. Contact-wire texture (landscape)

Generate a clean, isolated thin horizontal metallic overhead railway conductor, industrial steel/copper-grey with subtle highlights and fine texture. No poles, insulators, thick beams, terrain, text, perspective vanishing point, or background. Straight horizontal strip, constant width along its length; leave margins. Transparent RGBA. Avoid prominent fixed clamps: stretching will distort them. Prepare as 512x48 2x sprite with scale 0.5. Actual sag, end anchors and rotations belong to the later runtime geometry renderer.

## Generation-to-game steps

1. Generate each source independently using an image model or draw by hand; export PNG with actual transparency. If transparency fails, remove the background before this pipeline; do not fake alpha with a checkerboard.
2. Record generator/model, generation date, prompt, source rights and any reference image rights in a local provenance note. Do not include copyrighted game art as training/reference material without rights.
3. Use scripts/sprites/prepare.py for alpha-bbox-preserving fit to the manifest dimensions. Reject clipped inputs; do not stretch aspect ratio.
4. Run scripts/sprites/pipeline.py production and scripts/sprites/api_contract.py on the review output.
5. Inspect dark/light/checker previews at game-scale zoom, compare against native industrial sprites in a real Factorio screenshot, revise until the human art gate passes.
6. Only then integrate the RotatedSprite layers and wire SpritePrototype into a separate mod test build, and verify in Factorio 2.1.20.

**Automation boundary:** The current GitHub Actions workflow generates deterministic synthetic fixtures and runs image QA. It does not call an image generation API or certify the aesthetic quality of a model-generated image.

## Reference correction: one-sided Г-shaped railway support

User reference: https://ru.dreamstime.com/%D1%8D%D0%BB%D0%B5%D0%BA%D1%82%D1%80%D0%B8%D1%84%D0%B8%D1%86%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%BD%D1%8B%D0%B9-%D0%B6%D0%B5%D0%BB%D0%B5%D0%B7%D0%BD%D0%BE%D0%B4%D0%BE%D0%B6%D0%BD%D1%8B%D0%B9-%D1%81%D1%82%D0%BE%D0%BB%D0%B1-%D0%BD%D0%B0-%D1%84%D0%BE%D0%BD%D0%B5-%D0%B3%D0%BE%D0%BB%D1%83%D0%B1%D0%BE%D0%B3%D0%BE-%D0%BD%D0%B5%D0%B1%D0%B0-image298067434 . This page was not accessible for direct image inspection in this session; geometry is taken from the user's explicit **Г-shaped** description, not copied from the stock photo. Do not copy/trance/watermark the stock image.

The mast is left of the track, the arm reaches **right** across the rail centreline. Pole ground origin is x=75, y=354 (not canvas centre x=128); with scale=0.5 the resulting Factorio shift is x=+0.828125 tiles, y=-2.53125 tiles. The mirrored left-reaching arm will require a separately verified variant/orientation later. Current generated `direction_count=1` does **not** rotate the arm with rail orientation. The arm should have no baked-in long span wires, since those belong to the runtime line renderer.

Raw art preparation uses `source_anchor_fraction` in the manifest relative to the nontransparent bounding box to align the mast base. The default is only an estimate; real generated art must be checked by a human for base alignment and may require changing these fractions.
