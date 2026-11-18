# Electrified Mainline 0.1.30: separate geometry and native topology

Experiment branch: experiment/25kv-catenary-art-030, forked from 0.1.29.
Stable main 0.1.24 unchanged.

## Explicit user requirements
Accept the approved two-wire Factorio-inspired contact suspension:
straight contact wire, sagging upper messenger, vertical droppers.
Never modify existing rail or C mast graphics/geometry. Retain
32-tile straight, 16-tile curved and 40-tile connector limit.

## Isolation
Previous native_wire_028 handles only edge.corner==true curved spans,
where normal 0.1.29 copper rendering remains visible.
New catenary_art_030 handles only straight contact edges, keeping real
invisible native electric pole connectors and sprite-rendered wires.
Two helper prototype types may coexist at the same pole at a junction.
No data.raw utility-sprites copper_wire override exists in this patch.
All normal factory copper wires remain vanilla.

## Visual implementation
3 tiny RGBA source assets: contact-030.png (128x10),
messenger-030.png (128x10), dropper-030.png (10x32).
Runtime LuaRendering.draw_sprite creates a straight contact conductor,
3-12 short rotated messenger segments following stylized sag, and 2-8
vertical droppers spaced by span length. No rendering.draw_line.
Reuse draw-object IDs by geometric endpoint signature. Destroy on
segment/rail/parent removal. Sprite layering is object (arm overlays
on higher-object-above), pending actual screenshot verification.

## Limits
No traction power, 25kV nominal label only, transfer_MW=0.
Curve artwork postponed (fallback native single copper line).
Physical rail graph and 0.1.29 connectivity code unchanged.
Static CI cannot verify pixel-perfect game scale and occlusion.
