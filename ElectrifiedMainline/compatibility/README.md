# Compatibility layer

This directory is reserved for optional integrations with other mods.

Rules:

1. The core mod must work without optional mods.
2. Detect optional mods through Factorio's supported mod metadata/API; never assume they are installed.
3. An adapter may adjust our own prototypes or recipes, but must not mutate another mod's prototypes unless a specific integration requires it and is documented.
4. Keep integrations isolated by mod name and guard every referenced optional prototype.
5. Unknown rails, locomotives and wagons must not crash or be treated as Electrified Mainline objects.
6. Do not copy source code from Electrified Railways. It is an ideas/reference source only; all implementation must be independently written.

No adapters are implemented yet. Do not infer compatibility from the presence of this directory.
