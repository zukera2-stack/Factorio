# Prototype layer

## Current layout

- `bootstrap.lua` contains the existing prototype definitions and is loaded by the root `data.lua`.
- Root `data-updates.lua` and `data-final-fixes.lua` remain Factorio entry points and are intentionally kept at the mod root.

## Why the prototype definitions are not split yet

The current prototype file contains interdependent item, recipe, technology, rail, pole, locomotive and wagon definitions. Splitting it mechanically before each dependency is mapped risks changing load order or prototype semantics.

The next safe refactor is to extract one domain at a time:

1. items;
2. recipes;
3. technologies;
4. rails;
5. rolling stock;
6. power infrastructure.

Each extraction must preserve prototype names and load order, then pass a Factorio 2.1 data-stage test. Do not create empty placeholder modules or duplicate prototype definitions.
