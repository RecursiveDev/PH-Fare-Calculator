# Phase 5: Fixes, Features, and Optimization Plan

## Executive Summary
This phase focuses on stabilizing the MVP and adding critical usability features identified during user testing. Key objectives include resolving data duplication in Saved Routes, refactoring the Settings Screen to reduce visual bloat, implementing Group/Passenger fare calculations, adding Fare Sorting capabilities, and polishing the Reference Screen layout. These changes will improve data integrity, user experience, and the accuracy of fare estimations for groups.

## 1. Analysis & Root Causes

### 1.1 Saved Route Issues
*   **Symptoms:** Duplicate entries for the same route; clutter in the saved list.
*   **Root Cause:** The `FareRepository.saveRoute` method simply appends new entries to the Hive box without checking if a route with the same Origin and Destination already exists.
*   **Proposed Fix:** Implement "Upsert" (Update or Insert) logic. If a route with the same Origin and Destination names exists, overwrite it (updating the timestamp and fare results); otherwise, create a new entry.

### 1.2 Settings Screen Bloat
*   **Symptoms:** The screen is too long and repetitive. It lists "Transport Modes" (Descriptions) and "Available Transport Options" (Toggles) in two separate, disconnected sections.
*   **Root Cause:** Poor UI organization separating metadata (descriptions) from controls (toggles).
*   **Proposed Fix:** Unified UI. Create a `TransportModeSettingsCard` that groups the Mode Icon, Description, and SubType toggles into a single coherent card per Transport Mode.

### 1.3 Missing Group/Passenger Logic
*   **Symptoms:** Fares are always calculated for a single passenger, making the app less useful for groups.
*   **Root Cause:** `HybridEngine` and `FareFormula` assume a quantity of 1. Public transport (Jeep, Bus) is per-head, while private transport (Taxi) is usually per-ride.
*   **Proposed Fix:**
    *   Add `isPerHead` property to `FareFormula`.
    *   Update `HybridEngine` to accept `passengerCount`.
    *   Add Passenger Count selector to `MainScreen`.

### 1.4 Fare Sorting
*   **Symptoms:** Results are statically sorted by lowest price. Users cannot prioritize other factors.
*   **Root Cause:** Hardcoded sorting logic in `MainScreen`.
*   **Proposed Fix:** Introduce a Sort selector (Lowest Price, Highest Price, Mode Name) and apply dynamic sorting.

### 1.5 Reference Screen Layout
*   **Symptoms:** Inconsistent styling compared to the new Settings design; potential overflow or spacing issues.
*   **Root Cause:** Ad-hoc widget construction.
*   **Proposed Fix:** Standardize using the same card styling concepts as the refactored Settings screen.

## 2. Technical Design

### 2.1 Data Models

#### `FareFormula` (Update)
Add a flag to distinguish between per-person and per-ride fares.
```dart
@HiveType(typeId: 0)
class FareFormula {
  // ... existing fields ...
  @HiveField(7)
  final bool isPerHead; // Default to true for public, false for taxi/rentals
}
```

#### `FareResult` (Update)
Add context about the calculation.
```dart
@HiveType(typeId: 2)
class FareResult {
  // ... existing fields ...
  @HiveField(4)
  final int passengerCount; 
}
```

### 2.2 JSON Configuration (`assets/data/fare_formulas.json`)
Update all entries to include `is_per_head`.
*   `true`: Jeepney, Bus, Train, Ferry, Motorcycle (Angkas - usually per head), UV Express.
*   `false`: Taxi, Tricycle (Special/Pakyaw).

### 2.3 Logic Updates (`HybridEngine`)
Update `calculateDynamicFare`:
```dart
Future<double> calculateDynamicFare({
  // ... params
  int passengerCount = 1,
}) async {
  // ... base calculation ...
  double totalFare = formula.baseFare + (adjustedDistance * formula.perKmRate);
  
  // Apply Multiplier
  if (formula.isPerHead) {
    totalFare *= passengerCount;
  }
  
  // ... rest of logic (Discounts applied per head or total? Usually per head eligible, but we will apply to total for MVP simplicity assuming homogeneous group, or just apply discount logic before multiplier if needed. 
  // BETTER LOGIC: Calculate single fare with discount, THEN multiply by count.
  // BUT: Taxis don't get student discounts.
  // REFINED LOGIC: 
  // 1. Calculate Unit Fare (Base + Distance).
  // 2. Apply Mode Specifics (Provincial, Traffic).
  // 3. Apply Discount (if eligible and mode supports it).
  // 4. If (isPerHead) Final = Unit * Count else Final = Unit.
}
```

## 3. Implementation Steps

### Step 1: Model & Data Updates
1.  **Update `FareFormula`**: Add `isPerHead` field, update `fromJson`, and regenerate Hive adapter.
2.  **Update `assets/data/fare_formulas.json`**: Add `is_per_head` property to all records.
3.  **Update `FareRepository`**: Implement `saveRoute` with deduplication logic (check `origin` + `destination`).

### Step 2: Logic Implementation
4.  **Update `HybridEngine`**: Modify `calculateDynamicFare` to accept `passengerCount` and apply `isPerHead` logic.
5.  **Update `FareComparisonService`**: Ensure recommendations align with new logic (optional, mainly visual).

### Step 3: UI Refactoring (Settings)
6.  **Create `TransportModeSettingsCard`**: A reusable widget displaying mode info and list of subtype toggles.
7.  **Refactor `SettingsScreen`**: Replace the two separate lists with a single list of `TransportModeSettingsCard`s.

### Step 4: Feature Implementation (Main Screen)
8.  **Add Passenger Counter**: A simple `Row` with `[- 1 +]` controls in `MainScreen`.
9.  **Add Sort Selector**: A `DropdownButton` or `ChoiceChip` set for sorting results.
10. **Update Calculation**: Pass `passengerCount` to `HybridEngine`.
11. **Update Sorting**: Sort `_fareResults` based on selection.

### Step 5: Reference Screen Polish
12. **Update `ReferenceScreen`**: Align card styling with the new `SettingsScreen` components.

### Step 6: Verification
13. **Manual Test**: Verify Save deduplication, Group fare math (Taxi vs Jeep), Settings toggles, and Sorting.

## 4. Risk Assessment
*   **Hive Adapter Mismatch:** Modifying `FareFormula` requires regenerating the adapter. If `build_runner` fails, we must manually update `lib/src/models/fare_formula.g.dart`.
*   **Migration:** Existing app installs might have cached formulas without `isPerHead`. `FareRepository.seedDefaults(force: true)` might be needed or handled via migration logic.