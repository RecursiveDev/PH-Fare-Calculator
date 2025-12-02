# MVP Technical Implementation Plan

**Date**: December 3, 2025
**Version**: 1.0
**Status**: Approved for Implementation
**Author**: Architect Mode

## 1. Executive Summary

This plan outlines the technical steps to bridge the gap between the current Beta state and a polished MVP for the PH Fare Estimator. The focus is on implementing high-impact recommendations from the "Gap Analysis" report, specifically addressing user location persistence, passenger type consolidation, map boundary constraints, and fare sorting logic.

**Key Objectives:**
1.  **Enhance User Experience**: Persist last known location and passenger type to reduce repetitive input.
2.  **Improve Data Accuracy**: Consolidate passenger types into a unified `DiscountType` enum and ensure all logic respects this.
3.  **Refine UI/UX**: Limit map interactions to the Philippines to prevent invalid routing queries and sort results by "Best Value".
4.  **Solidify Architecture**: Centralize logic for passenger types and update documentation to reflect the current state.

## 2. Implementation Steps

### Phase 1: Location & Map Constraints (High Priority)
**Goal**: Restrict the app's focus to the Philippines and remember where the user last was.

1.  **Update `SettingsService` for Location Persistence**
    *   **Task**: Add methods to save and load the last known `Location` (name, lat, long).
    *   **File**: `lib/src/services/settings_service.dart`
    *   **Details**:
        *   Keys: `_keyLastLatitude`, `_keyLastLongitude`, `_keyLastLocationName`.
        *   Methods: `saveLastLocation(Location)`, `getLastLocation()`.

2.  **Implement Map Constraints in `MapSelectionWidget`**
    *   **Task**: Restrict the `flutter_map` camera to Philippines bounds.
    *   **File**: `lib/src/presentation/widgets/map_selection_widget.dart`
    *   **Details**:
        *   Define `LatLngBounds` for Philippines (approx. South-West: 4.5, 116.0; North-East: 21.5, 127.0).
        *   Apply `cameraConstraint` in `MapOptions`.
        *   Set `minZoom` to 5.0 to prevent zooming out too far.

3.  **Integrate Location Persistence in `MainScreen`**
    *   **Task**: Load last location on startup and auto-fill "Origin" if available. Save location when a route is calculated.
    *   **File**: `lib/src/presentation/screens/main_screen.dart`
    *   **Details**:
        *   In `initState`, call `SettingsService.getLastLocation()`.
        *   If found, update `_originLocation`, `_originLatLng`, and the text controller.
        *   In `_calculateFare`, call `SettingsService.saveLastLocation(_originLocation)`.

### Phase 2: Passenger Type Consolidation & UI (Medium Priority)
**Goal**: Ensure "Discount Type" is the single source of truth for "Passenger Type" and prompt new users.

1.  **Refactor Passenger Type Logic**
    *   **Task**: Verify `DiscountType` enum is fully utilized and centralized.
    *   **File**: `lib/src/models/discount_type.dart` (Already exists, verify usage).
    *   **Action**: Ensure `SettingsService` uses `DiscountType` exclusively for user type storage (already implemented, verify persistence keys match legacy if any).

2.  **Implement "First Time User" Prompt**
    *   **Task**: Show a dialog asking for passenger type if not yet set (or on first run).
    *   **File**: `lib/src/presentation/screens/main_screen.dart`
    *   **Details**:
        *   Check `SettingsService` for a "passenger_type_set" flag or null value.
        *   If not set, show `showDialog` with choices (Regular, Student, Senior, PWD).
        *   Save selection to `SettingsService`.

### Phase 3: Fare Logic & Sorting (High Priority)
**Goal**: Help users identify the "best" option immediately.

1.  **Implement "Smart Sorting"**
    *   **Task**: Sort fare results by price (cheapest first) by default.
    *   **File**: `lib/src/presentation/screens/main_screen.dart`
    *   **Details**:
        *   In `_calculateFare`, after generating `_fareResults`, apply `.sort((a, b) => a.fare.compareTo(b.fare))`.

2.  **Update `FareResult` Model**
    *   **Task**: Add `isRecommended` flag to highlight the best option.
    *   **File**: `lib/src/models/fare_result.dart`
    *   **Details**:
        *   Add `final bool isRecommended;` to class and Hive adapter.
        *   In `MainScreen`, mark the first item in the sorted list as `isRecommended: true`.

3.  **Update `FareResultCard` UI**
    *   **Task**: Display a visual badge for the recommended option.
    *   **File**: `lib/src/presentation/widgets/fare_result_card.dart`
    *   **Details**:
        *   If `isRecommended` is true, show a "Best Value" icon or badge (e.g., Star icon or distinct border/background).

### Phase 4: Documentation & Cleanup (Low Priority)
**Goal**: Align documentation with reality.

1.  **Update Fare Reference Guide**
    *   **Task**: Ensure `ReferenceScreen` reflects the latest `fare_formulas.json` (already dynamic, verify generic text).
    *   **File**: `lib/src/presentation/screens/reference_screen.dart`

2.  **Update Transport Mode Descriptions**
    *   **Task**: Verify `assets/data/fare_formulas.json` has clear descriptions for all modes.

## 3. Verification Checklist

*   [ ] **Location**: Restart app. Does "Origin" auto-fill with the last used location?
*   [ ] **Map**: Can you pan the map to Tokyo? (Should be NO).
*   [ ] **Sorting**: Calculate a route. Is the cheapest option at the top?
*   [ ] **Badging**: Does the top option have a "Best Value" visual indicator?
*   [ ] **Prompt**: On a fresh install (or cleared data), does the app ask "Are you a Student/Senior/PWD?"?
*   [ ] **Routing**: Does `OsrmRoutingService` fail gracefully if the user tries to route across oceans (Inter-island)? (Note: Full inter-island guard is complex, basic check is sufficient for MVP).

## 4. Risks & Mitigations

*   **Risk**: `flutter_map` constraints might feel "sticky" if too tight.
    *   *Mitigation*: Add substantial padding to the bounds (include nearby seas).
*   **Risk**: "Best Value" might not always be the *fastest*.
    *   *Mitigation*: For MVP, "Best Value" = Cheapest. Future updates can balance time vs. cost.
*   **Risk**: OSRM might return "driving" routes for ferries.
    *   *Mitigation*: Accept for MVP, but advise user to check Reference Guide for island hops.
