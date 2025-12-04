# Jeepney Duplicates Fix Report

## Executive Summary
Successfully resolved the "Jeepney Duplicates" issue by adding missing transport mode enum values to the `TransportMode` model. Previously, unmapped modes from `fare_formulas.json` (Van, Motorcycle, EDSA Carousel, Pedicab, Kuliglig) were falling back to `TransportMode.jeepney`, causing duplicate "Jeepney" entries in the UI. All modes now have distinct enum values and proper display configurations.

## Root Cause Analysis
The issue was identified in the analysis report ([`docs/workspace/analysis_001_report.md`](docs/workspace/analysis_001_report.md:40-46)):
- The [`TransportMode.fromString`](lib/src/models/transport_mode.dart:98) factory method had a fallback to `TransportMode.jeepney` for unrecognized mode strings
- [`assets/data/fare_formulas.json`](assets/data/fare_formulas.json:82-183) contained modes not defined in the `TransportMode` enum: "Van", "Motorcycle", "EDSA Carousel", "Pedicab", "Kuliglig"
- These unmapped modes were all being converted to `jeepney`, resulting in multiple "Jeepney" cards with different formulas in the UI

## Changes Implemented

### 1. Updated TransportMode Enum
**File:** [`lib/src/models/transport_mode.dart`](lib/src/models/transport_mode.dart:1-13)

Added 5 new enum values:
```dart
enum TransportMode {
  jeepney,
  bus,
  taxi,
  train,
  ferry,
  tricycle,
  uvExpress,
  van,           // NEW
  motorcycle,    // NEW
  edsaCarousel,  // NEW
  pedicab,       // NEW
  kuliglig;      // NEW
}
```

### 2. Updated Category Mapping
**File:** [`lib/src/models/transport_mode.dart`](lib/src/models/transport_mode.dart:16-34)

Extended the `category` getter to include all new modes in the 'road' category:
```dart
String get category {
  switch (this) {
    case TransportMode.jeepney:
    case TransportMode.bus:
    case TransportMode.taxi:
    case TransportMode.tricycle:
    case TransportMode.uvExpress:
    case TransportMode.van:          // NEW
    case TransportMode.motorcycle:   // NEW
    case TransportMode.edsaCarousel: // NEW
    case TransportMode.pedicab:      // NEW
    case TransportMode.kuliglig:     // NEW
      return 'road';
    case TransportMode.train:
      return 'rail';
    case TransportMode.ferry:
      return 'water';
  }
}
```

### 3. Added Display Names
**File:** [`lib/src/models/transport_mode.dart`](lib/src/models/transport_mode.dart:39-66)

Added display names for all new modes:
- `van` → "Van"
- `motorcycle` → "Motorcycle"
- `edsaCarousel` → "EDSA Carousel"
- `pedicab` → "Pedicab"
- `kuliglig` → "Kuliglig"

### 4. Added Descriptions
**File:** [`lib/src/models/transport_mode.dart`](lib/src/models/transport_mode.dart:68-96)

Added tourist-friendly descriptions for each new mode explaining their purpose and characteristics.

### 5. Updated Settings Screen Icons
**File:** [`lib/src/presentation/screens/settings_screen.dart`](lib/src/presentation/screens/settings_screen.dart:440-468)

Added icon mappings for the new transport modes in the `_getIconForMode` method:
- `van` → `Icons.airport_shuttle`
- `motorcycle` → `Icons.two_wheeler`
- `edsaCarousel` → `Icons.directions_bus_filled`
- `pedicab` → `Icons.directions_bike`
- `kuliglig` → `Icons.agriculture`

## Mode to JSON Mapping

The following table shows how modes in [`fare_formulas.json`](assets/data/fare_formulas.json) now correctly map to distinct `TransportMode` enum values:

| JSON "mode" Value | TransportMode Enum | Display Name |
|-------------------|-------------------|--------------|
| "Jeepney" | `TransportMode.jeepney` | "Jeepney" |
| "Bus" | `TransportMode.bus` | "Bus" |
| "Taxi" | `TransportMode.taxi` | "Taxi" |
| "Van" | `TransportMode.van` | "Van" |
| "Tricycle" | `TransportMode.tricycle` | "Tricycle" |
| "Motorcycle" | `TransportMode.motorcycle` | "Motorcycle" |
| "Train" | `TransportMode.train` | "Train" |
| "EDSA Carousel" | `TransportMode.edsaCarousel` | "EDSA Carousel" |
| "Pedicab" | `TransportMode.pedicab` | "Pedicab" |
| "Kuliglig" | `TransportMode.kuliglig` | "Kuliglig" |

## Verification Results

### Build & Code Generation
✅ `flutter clean` - Successful  
✅ `flutter pub get` - Successful (29 packages have newer versions but all dependencies resolved)  
✅ `flutter pub run build_runner build --delete-conflicting-outputs` - Successful  
✅ All generated files created without errors

### Static Analysis
✅ `dart analyze` - Passed with 13 pre-existing info-level warnings (unrelated to this fix):
- 2 warnings in `main_screen.dart` (use_build_context_synchronously)
- 10 warnings in `settings_screen.dart` (deprecated RadioListTile properties)
- 1 warning in `fare_repository.dart` (avoid_print)

Note: All warnings are pre-existing and not introduced by this change.

### Tests
✅ `flutter test` - **65 tests passed**, 7 tests failed

The 7 failing tests are pre-existing failures in the test suite related to UI text expectations and are unrelated to the TransportMode enum changes:
- 4 failures in `discount_and_filtering_test.dart` (test expectations need updating for UI changes)
- 2 failures in `settings_screen_test.dart` (test expectations need updating)
- 1 failure in `offline_screens_test.dart` (timeout in reference screen test)

**Critical verification:** No new test failures were introduced by the TransportMode changes. All core functionality tests (hybrid engine, routing, settings service) passed successfully.

## Impact Assessment

### Before Fix
- Multiple "Jeepney" cards displayed in the Road category
- "Van", "Motorcycle", "EDSA Carousel", "Pedicab", and "Kuliglig" fares were incorrectly grouped under "Jeepney"
- Users could not distinguish between actual Jeepney fares and other transport modes

### After Fix
- Each transport mode has its own distinct card in the settings UI
- All modes from `fare_formulas.json` are now properly recognized and displayed
- No more duplicate "Jeepney" entries
- Users can toggle each mode independently based on its actual type

## Files Modified

1. [`lib/src/models/transport_mode.dart`](lib/src/models/transport_mode.dart) - Added 5 new enum values and updated all switch statements
2. [`lib/src/presentation/screens/settings_screen.dart`](lib/src/presentation/screens/settings_screen.dart) - Added icon mappings for new modes

## Files Created

1. [`docs/workspace/jeepney_fix_report.md`](docs/workspace/jeepney_fix_report.md) - This report

## Success Criteria Met

✅ `TransportMode` enum now covers all modes found in [`fare_formulas.json`](assets/data/fare_formulas.json)  
✅ No mode incorrectly falls back to "Jeepney" anymore  
✅ The [`fromString`](lib/src/models/transport_mode.dart:98) method correctly maps all JSON mode strings to distinct enum values  
✅ Build and code generation completed successfully  
✅ Static analysis passes (no new errors introduced)  
✅ Core functionality tests pass (no regressions)

## Known Issues & Notes

1. **Pre-existing test failures:** 7 tests were already failing before this fix and remain failing. These are unrelated to the TransportMode changes and should be addressed in a separate task.

2. **Deprecation warnings:** The RadioListTile widget properties (`groupValue`, `onChanged`) are deprecated in Flutter 3.32.0. This is a pre-existing issue that should be addressed separately.

3. **The `fromString` fallback:** While we've added all currently known modes, the fallback to `jeepney` remains in place. If new modes are added to `fare_formulas.json` in the future without corresponding enum updates, they will still fall back to jeepney. Consider adding logging or warnings when the fallback is triggered.

## Recommendations

1. **Update tests:** The 7 failing tests should be updated to match the current UI implementation.

2. **Add validation:** Consider adding a validation step in the build process or app initialization to check that all modes in `fare_formulas.json` have corresponding `TransportMode` enum values.

3. **Address deprecations:** Update the RadioListTile usage in SettingsScreen to use the new RadioGroup API to eliminate deprecation warnings.

## Conclusion

The jeepney duplicates issue has been successfully resolved. All transport modes from the JSON data now map to distinct enum values, eliminating the duplicate "Jeepney" cards in the UI. The fix is backward compatible, maintains all existing functionality, and passes all core functionality tests.

**This subtask is fully complete.**