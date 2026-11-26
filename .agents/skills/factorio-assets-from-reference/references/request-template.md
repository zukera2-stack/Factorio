# Asset job — compact request record (copy per task)

Do **not** display this as a long user form. Fill from the user's messages and verified files. Ask only when the source/output is truly ambiguous.

```yaml
asset_job: EM086-cargo-concept
intent: reference_study        # study | concept | repaint | component | sprites | patch
object_prototype: em-motor-cargo-wagon
source:
  kind: owner_game_screenshot # official_base_png | owner_game_screenshot | V3_model | own_png | generated_concept
  path: /Factorio/References/Motor-Wagon-Vanilla-Sprite-Studies/cargo_actual_screenshot_before_after_2d_preview.zip
  sha256: UNKNOWN_UNTIL_EXACT_BYTES_READ
  source_game_version: OWNER_GAME_VERSION_IF_KNOWN
allowed_changes:
  - grayscale_recolor_of_existing_hopper_panels
  - small_red_stripe
  - separate_motor_bogie_preview
protected:
  - hopper_silhouette_and_cargo_function
  - coupling_points_and_rail_scale
  - locomotive_approved_assets
forbidden:
  - new_passenger_body
  - extra_wagon_pantograph
  - move_bogie_without_geometry_proof
runtime:
  native_type: cargo-wagon
  frame_count: UNKNOWN_REQUIRE_REAL_BASE_SOURCE
  sprite_frame_size: UNKNOWN_REQUIRE_REAL_BASE_SOURCE
  source_shift: UNKNOWN_REQUIRE_REAL_BASE_SOURCE
  wheels_native_contract: UNKNOWN_REQUIRE_REAL_BASE_SOURCE
output:
  class: study
  game_ready: false
  ui_review: source_and_edited_same_frame
  qa_report: build/qa/EM086_cargo_study.json
  owner_status: pending
```

Source field values `UNKNOWN_REQUIRE_REAL_BASE_SOURCE` are genuine blockers, not invitations to invent data. The same record becomes a reproducible runtime contract only after genuine sprite assets and prototype parameters are acquired and QA has passed.
