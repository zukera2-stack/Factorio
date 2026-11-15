-- 0.1.18: dedicated build modifier. Ordinary left-click is not intercepted.
-- The event is handled only if the real catenary-pole item is in the cursor.
data:extend({
    {
        type="custom-input",
        name="em-place-catenary-native",
        key_sequence="ALT + mouse-button-1",
        consuming="game-only",
        action="lua",
    }
})
