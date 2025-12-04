# Analysis Report: PH Fare Estimator Issues (Subtask analysis_001)

## Executive Summary
This report identifies the root causes and file locations for 6 reported issues in the PH Fare Estimator codebase.
1. **Crash**: Caused by a schema mismatch in `FareResultAdapter` where a new boolean field lacks a default value.
2. **Group Fares**: Inputs exist in UI but rely on missing JSON configuration to function.
3. **Reference UI**: Inconsistent widget implementations across different sections in `ReferenceScreen`.
4. **Jeepney Duplicates**: Caused by unmapped transport modes in JSON falling back to "Jeepney" in `TransportMode.fromString`.
5. **Calculation Logic**: `is_per_head` property is missing from `fare_formulas.json`, preventing group fare multiplication.
6. **Traffic Colors**: Traffic factor indicators are applied globally to all modes in `MainScreen` instead of being mode-specific.

---

## Detailed Findings

### 1. Save Route Crash
*   **Issue:** `type 'Null' is not a subtype of type 'bool'`
*   **Root Cause:** The `FareResult` Hive adapter attempts to read `isRecommended` (index 3) as a non-nullable `bool`. Legacy data or uninitialized fields return `null`, causing the crash.
*   **Location:**
    *   `lib/src/models/fare_result.g.dart`: Line 23 (`isRecommended: fields[3] as bool`).
    *   `lib/src/models/fare_result.dart`: Line 24 (`final bool isRecommended;`).
*   **Remediation:** Update `FareResult` model to ensure the Hive field has a default value (e.g., `@HiveField(3, defaultValue: false)`) and regenerate the adapter.

### 2. Group Fare Feature (Inputs + Logic)
*   **Status:** UI inputs and core logic are **present** but may appear broken due to missing data configuration (see Issue #5).
*   **Location:**
    *   **UI Inputs:** `lib/src/presentation/screens/main_screen.dart` (Lines 322-541: `_buildPassengerCountSelector` and `_showPassengerDialog`).
    *   **Logic:** `lib/src/core/hybrid_engine.dart` (Lines 253-288: `calculateDynamicFare` handles `regularCount` and `discountedCount`).
*   **Remediation:** Ensure UI inputs are correctly passing data (verified) and fix the underlying data issue in `fare_formulas.json`.

### 3. Reference Guide UI Layout
*   **Issue:** Inconsistent card/list layouts between Road, Train, and Ferry sections.
*   **Location:** `lib/src/presentation/screens/reference_screen.dart`
    *   **Road Section:** Uses `_FareFormulaRow` with `LayoutBuilder` (Lines 211-258).
    *   **Train Section:** Uses custom cards with summary stats (Lines 260-366).
    *   **Ferry Section:** Uses `ExpansionTile` widgets (Lines 368-444).
*   **Remediation:** Standardize the widget structure (likely adopting the `ExpansionTile` or a unified Card approach) across all sections.

### 4. Jeepney Duplicates in Road Category
*   **Issue:** Multiple distinct JSON modes (e.g., "Van", "Motorcycle", "Pedicab") are being grouped under "Jeepney".
*   **Root Cause:** The `TransportMode.fromString` factory method falls back to `TransportMode.jeepney` for any unrecognized string. Since "Van", "Motorcycle", etc., are in the JSON but not in the `TransportMode` enum, they are all converted to `jeepney` object type but keep their formula list, resulting in multiple "Jeepney" cards in the UI.
*   **Location:**
    *   **Logic:** `lib/src/models/transport_mode.dart` (Lines 68-73: Fallback logic).
    *   **Data:** `assets/data/fare_formulas.json` (Contains unmapped modes like "Van", "Motorcycle", "EDSA Carousel").
    *   **Grouping:** `lib/src/presentation/screens/settings_screen.dart` (Lines 274-288: Groups by `TransportMode` enum).
*   **Remediation:** Add missing values to `TransportMode` enum or map them correctly (e.g., "Van" -> `uvExpress`).

### 5. Fare Calculation Logic
*   **Issue:** Passenger count multipliers are not applied to relevant modes (Jeepney/Bus).
*   **Root Cause:** The `calculateDynamicFare` method in `HybridEngine` relies on `formula.isPerHead`. However, the `assets/data/fare_formulas.json` file is missing the `is_per_head` key for all entries, causing it to default to `false`.
*   **Location:**
    *   **Data:** `assets/data/fare_formulas.json` (Missing `"is_per_head": true` for Jeepney, Bus, etc.).
    *   **Logic:** `lib/src/core/hybrid_engine.dart` (Lines 259, 283: checks `formula.isPerHead`).
*   **Remediation:** Update `fare_formulas.json` to include `"is_per_head": true` for per-passenger modes.

### 6. Traffic Factor Color Logic
*   **Issue:** Traffic congestion colors (Green/Amber/Red) are applied to all transport modes, even those unaffected by traffic (like Trains) or where fare doesn't surge (Jeepneys).
*   **Root Cause:** In `MainScreen`, the `indicatorLevel` is calculated once based on the global traffic setting and applied to **every** `FareResult` object, regardless of the transport mode.
*   **Location:**
    *   `lib/src/presentation/screens/main_screen.dart`: Lines 897 (calculation) and 906 (assignment).
*   **Remediation:** Move `getIndicatorLevel` logic inside the loop or `HybridEngine` to return `IndicatorLevel.standard` for modes that are not "Taxi" (or other traffic-sensitive modes).

---

## Files to Modify

| Issue | Files |
|-------|-------|
| **1. Crash** | `lib/src/models/fare_result.dart` (Update annotation), `lib/src/models/fare_result.g.dart` (Regenerate) |
| **2. Group Fare** | *Dependent on Issue 5 Fix* |
| **3. Ref UI** | `lib/src/presentation/screens/reference_screen.dart` |
| **4. Duplicates** | `lib/src/models/transport_mode.dart`, `assets/data/fare_formulas.json` |
| **5. Calc Logic** | `assets/data/fare_formulas.json` |
| **6. Traffic Color** | `lib/src/presentation/screens/main_screen.dart` |