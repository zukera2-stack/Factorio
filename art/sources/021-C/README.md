# 0.1.21 C mast: full-resolution originals and exact game sprites

All **nine original full-resolution PNGs** are preserved in this GitHub tree with their exact original bytes:
`concept-C.png` (user-selected C concept), and `east.png`, `southeast.png`, `south.png`, `southwest.png`, `west.png`, `northwest.png`, `north.png`, `northeast.png`.

The eight 512×384 RGBA export frames used in **0.1.21 user-tested Factorio build** and the following 0.1.22 facing experiment are at `ElectrifiedMainline/graphics/entity/35kv/pole-*-012.png`. Exact original 0.1.21 ZIP (SHA256 `234f26cd11a1efa380dd849af2278234db3db90ec23b8049096c66cf0863da42`) is archived in [`art/archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip`](../../archives/ElectrifiedMainline_0.1.21_C-mast-art_TEST.zip). The ZIP includes `ART_021_SOURCE_MANIFEST.json` with per-direction crop and SHA256. It is **the same ZIP tested by the user**, not a regenerated or reduced-color copy.

| Original | Original source image from user chat | SHA256 |
|---|---|---|
| east.png | изометрическая_мачта_контактной_сети_35_кв.png | `69bde8545c060c85753c5d4e918d1a3e0118a66bbf007c7ea681469162a5429d` |
| southeast.png | юго_восточная_мачта_контактной_сети.png | `0b2c6d6c1f9d65493059e08678d299d4086dd5b2157f96b88912a8d6c73018a0` |
| south.png | южная_мачта_контактной_сети.png | `9c83809f176c9e639ff16c608097aee101888b666aaad8d42a097aa673543900` |
| southwest.png | промышленная_мачта_контактной_сети.png | `aa5161fc1ff4ccf263e03c338d149d27c4b8d6dcba9eee13cb2beb97130df1e2` |
| west.png | западная_мачта_железнодорожной_контактной_сети.png | `ef8810f1bf6f27f214340ba113d24acfe865603b655b08e6eabe5e43f5142463` |
| northwest.png | северо_западная_мачта_электрифицированной_железной.png | `c9b9e4705a0b03f75016f8ac7b6703a6c7eb23c814a1c22a5eefb13a3ca14949` |
| north.png | изолированная_железнодорожная_мачта_с_контактной_с.png | `fb2fec13e79bafae58fe2da7e75f1b34e6521d11f714e11945b3c1f438262b76` |
| northeast.png | промышленная_ne_мачта_контактной_сети.png | `b73dccf65842312a7645cc38b6513e69daec083b499a6cabe40b726b6e58d12c` |

**Art policy from user:** SOUTH should look like EAST's pleasing side perspective; NORTH like WEST's perspective. These are artistic choices and do not replace the spatial facing algorithm. The current 0.1.22 code projects onto RailEnd geometry; the game must confirm it.

Full-sized raw user screenshots from 2026-11-15 total 28 MB and are kept as user conversation attachments; the **six-screenshot contact sheet** and exact original ZIP/PNG hashes are in [user game-test report](../../../docs/tests/catenary-C-art-0.1.21-facing-2026-11-15.md).
