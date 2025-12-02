# Research Report: MVP Gap Analysis & Recommendations

**Date**: December 3, 2025
**Scope**: Codebase Analysis for MVP Feature Completeness
**Author**: Technical Librarian

## 1. Executive Summary

The `ph-fare-estimator` application has established a solid "Local-First" architectural foundation. The core `HybridEngine` successfully orchestrates dynamic routing (via OSRM) and static matrix lookups, while the `SettingsService` manages user preferences effectively.

However, to meet the "Minimum Viable Product" (MVP) definition outlined in the PRD, the application currently lacks critical **user guidance** and **feedback mechanisms**. While the *calculation* logic is sound, the *presentation* of data is raw. The user is presented with a list of fares without context (which is "best"?), and error states (e.g., offline routing failure) need more robust handling.

This report outlines specific, high-impact features to bridge the gap between the current Beta state and a polished MVP.

## 2. Feature Gap Analysis

| Feature Area | PRD Requirement | Current Implementation Status | MVP Gap Severity |
| :--- | :--- | :--- | :--- |
| **Comparison** | "Recommended" (Cheapest/Fastest) highlighting. | Lists all results sequentially. No sorting or highlighting. | **High** |
| **Offline** | Static "Cheat Sheets" for reference. | Logic exists in `HybridEngine`, but no dedicated UI to *browse* tables without calculating a route. | **Medium** |
| **Routing** | Inter-island routing mitigation. | `OsrmRoutingService` returns raw routes. No detection of water crossing failure. | **Medium** |
| **Privacy** | Local-first / Privacy-centric. | Direct calls to public OSRM API expose user location. | **Medium** (Acceptable for MVP if disclosed) |
| **Feedback** | "Report your Fare" / Correction. | Non-existent. Users cannot report discrepancies. | **High** (Critical for trust) |
| **UI/UX** | "Scam Detector" Visuals. | Implemented via `FareResultCard` colors (Green/Yellow/Red). | **Low** (Mostly done) |

## 3. Recommended Functionality (MVP Focus)

The following features are recommended for immediate implementation to finalize the MVP. They focus on **usability** and **trust**.

### A. Smart Result Sorting & "Best Option" Badge
**Problem**: The `MainScreen` simply iterates through visible formulas and displays them. A user usually wants to know "What is cheapest?" or "What is fastest?" immediately.
**Recommendation**:
1.  **Logic**: Update `_calculateFare` in `MainScreen` to sort `_fareResults` by price (ascending).
2.  **UI**: Add a "Best Value" badge to the top result.
3.  **Implementation**:
    -   Modify `lib/src/presentation/screens/main_screen.dart`.
    -   Sort `results` list before `setState`.
    -   Add a `isRecommended` boolean to `FareResult` model.

### B. Static Matrix Browser (Offline Reference)
**Problem**: Users can only see Train/Ferry fares if they search for specific station names. They cannot simply "look up" the price table, which is a key use case for tourists.
**Recommendation**:
1.  **Feature**: Create a "Reference Tables" section in `OfflineMenuScreen`.
2.  **UI**: Simple list views that render the raw JSON data from `assets/data/train_matrix.json` and `ferry_matrix.json`.
3.  **Implementation**:
    -   Read `train_matrix.json` and render it as a DataTable or ListView.
    -   Allows users to verify prices even without GPS or route inputs.

### C. "Report Incorrect Fare" Mechanism
**Problem**: Fare formulas change rapidly. If the app shows ₱15.00 but the driver charges ₱20.00, the user loses trust immediately if they can't report it.
**Recommendation**:
1.  **Feature**: A simple "Report Issue" button on the `FareResultCard`.
2.  **Mechanism**: Since there is no backend, this should trigger a **pre-filled email intent** (`mailto:support@example.com?subject=Fare Discrepancy&body=Route: A to B, Mode: Jeep, App said: 15, Actual: ...`).
3.  **Value**: Provides a zero-cost feedback loop for the developer to update `fare_formulas.json`.

### D. Inter-Island Routing Guard
**Problem**: OSRM (Driving profile) often fails or returns crazy routes when crossing islands (e.g., Batangas to Calapan).
**Recommendation**:
1.  **Logic**: In `OsrmRoutingService`, if the route distance is unexpectedly large (>1000km for a known short trip) or fails, catch the error.
2.  **Fallback**: Suggest the "Ferry Matrix" explicitly in the UI. "Could not calculate road route. Are you crossing water? Check Ferry Rates."

## 4. Technical Recommendations

### Refactoring `FareComparisonService`
The file `lib/src/services/fare_comparison_service.dart` exists but is currently underutilized.
*   **Action**: Move the "Filtering" logic (currently in `MainScreen` lines 489-493) into this service.
*   **Goal**: Centralize all logic regarding *which* modes to show and *how* to rank them.

### Error Handling Standardization
The `Failure` classes in `lib/src/core/errors/failures.dart` are good, but their usage in `GeocodingService` vs `HybridEngine` is inconsistent.
*   **Action**: Ensure `HybridEngine` catches `NetworkFailure` from OSRM and wraps it in a user-friendly message ("Offline Mode Active - showing estimates based on straight-line distance" if implemented, or "Please connect to internet for road estimates").

## 5. Conclusion

The codebase is mature enough for an MVP release *if* the user experience regarding **choice** (Sorting/Best Value) and **fallback** (Static Tables) is addressed. The "Hybrid Engine" works, but the app needs to better guide the user when the "Dynamic" part fails or is overwhelming.

**Priority Order:**
1.  **Smart Result Sorting** (Quick win, high value).
2.  **Static Matrix Browser** (Critical for offline value prop).
3.  **Report Feedback Mechanism** (Critical for long-term data accuracy).