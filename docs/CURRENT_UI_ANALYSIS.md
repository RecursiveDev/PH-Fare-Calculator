# Current UI/UX Analysis Report

## Executive Summary
This report documents the current state of the User Interface and User Experience of the PH Fare Calculator application. The application utilizes a standard Material Design 3 theme with support for both light and dark modes (via high contrast setting). The current UI is functional but relies heavily on basic Material widgets (`Card`, `ListTile`, `ElevatedButton`) with minimal custom styling or branding. UX patterns are generally consistent, though some areas like the "passenger count" selection and "map picker" flow could be streamlined. Accessibility is partially implemented with `Semantics` widgets in critical areas.

## Global Theme & Configuration

### Dependencies (`pubspec.yaml`)
- **UI Framework:** Flutter SDK
- **Icons:** `cupertino_icons` (iOS style), Material Icons (default)
- **Map:** `flutter_map` ^8.2.2, `latlong2` ^0.9.1
- **Localization:** `flutter_localizations`, `intl`
- **State/Storage:** `hive_flutter`, `shared_preferences`, `provider` (implied via `flutter_bloc` or similar, though strictly `ValueListenableBuilder` is used in `main.dart`)

### Theme Settings (`lib/main.dart`)
- **Design System:** Material 3 (`useMaterial3: true`)
- **Light Theme:**
  - Seed Color: `Colors.deepPurple`
- **Dark Theme (High Contrast):**
  - Brightness: `Brightness.dark`
  - Background: `Colors.black`
  - Primary: `Colors.cyanAccent`
  - Secondary: `Colors.yellowAccent`
  - Surface: `Colors.black`
  - Error: `Colors.redAccent`
  - **Custom Typography:** `bodyMedium` (White, Bold), `titleLarge` (CyanAccent, Bold)
  - **Input Decoration:** White borders (enabled), CyanAccent borders (focused)
  - **Card Theme:** Black color, White border (2.0 width), Rounded corners (12.0)

---

## Screen Analysis

### 1. Main Screen (`lib/src/presentation/screens/main_screen.dart`)
**Role:** The primary dashboard for route entry, map visualization, and fare calculation.

- **Visual Structure:**
  - `AppBar` with title and actions (Offline Reference, Settings).
  - `SingleChildScrollView` body containing a vertical column of form elements.
  - Two `Autocomplete<Location>` fields for Origin and Destination.
  - A custom `Passenger Count Selector` card.
  - A `MapSelectionWidget` (height: 300) showing the route.
  - A "Calculate Fare" `ElevatedButton`.
  - Results section with a "Save Route" button, Sort Dropdown, and a list of grouped `FareResultCard`s.

- **Styling:**
  - Standard Material padding (16.0).
  - Use of `Card` elevation for grouping inputs.
  - Results are grouped by transport mode with colored headers (`primaryContainer`).

- **UX Patterns:**
  - **Input:** Autocomplete text fields with debouncing (800ms).
  - **Feedback:** Loading spinners inside text fields. Error messages displayed as red text or Snackbars.
  - **Navigation:** Modal routes for Map Picker and Settings.

- **Issues / Improvement Areas:**
  - The map widget has a fixed height of 300, which might be cramped on larger screens or too large on small ones.
  - The "Passenger Count" selector opens a complex dialog; a bottom sheet might be more modern.
  - The "Calculate Fare" button is disabled until valid inputs are present, which is good practice but could use better visual cues for *why* it is disabled.

- **Accessibility:**
  - `Semantics` used for AppBar actions ("Open offline reference menu", "Open settings").
  - `Semantics` wrapper around the "Calculate Fare" button.
  - `Semantics` on text fields.

### 2. Map Picker Screen (`lib/src/presentation/screens/map_picker_screen.dart`)
**Role:** Full-screen map interface for selecting a location coordinate.

- **Visual Structure:**
  - `AppBar` with "Confirm" text button action.
  - Full-screen `FlutterMap`.
  - Fixed center crosshair icon (`Icons.add`).
  - Floating instructions card at the top.
  - `FloatingActionButton` to confirm selection (appears only when location selected).

- **Styling:**
  - Minimalist. Relies mostly on the map tiles.
  - Top instruction card uses standard Card styling.

- **UX Patterns:**
  - **Interaction:** Tap to select, or drag map to center.
  - **Feedback:** A marker appears where tapped. The center crosshair implies "target" selection mode.

- **Issues / Improvement Areas:**
  - The coexistence of "Tap to select" and "Center crosshair" can be confusing. Usually, it's one or the other (pin drags with map vs. tap to drop pin).
  - The top instruction card obscures map content.

- **Accessibility:**
  - No specific semantic labels documented for map interactions.

### 3. Offline Menu Screen (`lib/src/presentation/screens/offline_menu_screen.dart`)
**Role:** Simple navigation menu for offline features.

- **Visual Structure:**
  - `AppBar`.
  - `ListView` with `Card` widgets acting as menu items.

- **Styling:**
  - Large icons (size 40.0) in primary color.
  - Bold titles and body text descriptions.
  - `Chevron` right icon to indicate navigation.

- **UX Patterns:**
  - Standard list navigation pattern.

- **Issues / Improvement Areas:**
  - Very sparse. Could be a section in a drawer or a bottom tab instead of a separate screen.

- **Accessibility:**
  - Standard flutter widget accessibility.

### 4. Onboarding Screen (`lib/src/presentation/screens/onboarding_screen.dart`)
**Role:** Initial setup for language selection and welcome message.

- **Visual Structure:**
  - `Column` layout with `Spacer`s for vertical centering.
  - Welcome text, Language selection buttons (English/Tagalog), Disclaimer, and "Continue" button.

- **Styling:**
  - Large bold welcome text (24sp).
  - Language buttons use `FilledButton` (selected) vs `OutlinedButton` (unselected).

- **UX Patterns:**
  - **State:** Updates locale immediately via `SettingsService`.
  - **Navigation:** Replaces route with `MainScreen` upon completion.

- **Issues / Improvement Areas:**
  - Basic layout. No illustrations or carousel to explain app features.

- **Accessibility:**
  - `Semantics` applied to language buttons and the continue button.

### 5. Reference Screen (`lib/src/presentation/screens/reference_screen.dart`)
**Role:** Static informational screen showing fare tables and matrices.

- **Visual Structure:**
  - `ListView` containing multiple sections: Discount Info, Road Transport, Train, Ferry.
  - Uses `ExpansionTile` within `Card`s to organize large datasets.

- **Styling:**
  - Color-coded sections (Blue for discounts, Amber for warnings).
  - Dense lists for fare matrices.

- **UX Patterns:**
  - **Loading:** Shows `CircularProgressIndicator` while parsing JSON assets.
  - **Organization:** Collapsible sections (`ExpansionTile`) keep the view clean.

- **Issues / Improvement Areas:**
  - Text heavy.
  - The "Train Matrix" list can be very long; search or filter functionality would be beneficial.

- **Accessibility:**
  - Standard scrolling and tap targets.

### 6. Saved Routes Screen (`lib/src/presentation/screens/saved_routes_screen.dart`)
**Role:** Lists routes previously saved by the user.

- **Visual Structure:**
  - `ListView` of `Card` widgets.
  - Each card contains an `ExpansionTile` showing summary (Origin -> Dest) and detailed `FareResultCard`s when expanded.
  - Delete icon button in the trailing position.

- **Styling:**
  - Standard Card styling.
  - Date formatting using `intl`.

- **UX Patterns:**
  - **Empty State:** Simple text "No saved routes yet."
  - **Action:** Delete button removes item immediately (no undo mentioned in code).

- **Issues / Improvement Areas:**
  - No "Undo" action for deletion.
  - No way to "Re-calculate" or "Load" a saved route back into the Main Screen for updated pricing.

- **Accessibility:**
  - Standard controls.

### 7. Settings Screen (`lib/src/presentation/screens/settings_screen.dart`)
**Role:** Configuration for app behavior and preferences.

- **Visual Structure:**
  - `ListView` with `SwitchListTile` and `RadioListTile` widgets.
  - Sections: General (Provincial, High Contrast), Traffic Factor, Passenger Type, Transport Modes.

- **Styling:**
  - Standard Material settings list styling.
  - "Transport Modes" section dynamically generates cards with toggles for each sub-type.

- **UX Patterns:**
  - **Immediate Action:** Toggles and selections save immediately to `SettingsService`.

- **Issues / Improvement Areas:**
  - The "Transport Modes" list can get very long.
  - "Traffic Factor" radio buttons take up a lot of vertical space.

- **Accessibility:**
  - Standard form controls are generally accessible.

### 8. Splash Screen (`lib/src/presentation/screens/splash_screen.dart`)
**Role:** Bootstrapping logic (DI, DB, Seeding) before navigating to app.

- **Visual Structure:**
  - Simple `Scaffold` with a centered `FlutterLogo` (size 100).
  - Error state shows a red error icon and text if initialization fails.

- **Styling:**
  - Minimal.

- **UX Patterns:**
  - **Wait:** Forces a minimum 2-second delay even if loading is faster.
  - **Routing:** Decides between Onboarding vs Main Screen based on SharedPrefs.

- **Issues / Improvement Areas:**
  - Static logo. Could use an animated branding element.
  - No progress indicator during the "loading" phase (just logo).

- **Accessibility:**
  - Not interactive, essentially an image.

---

## Widget Analysis

### 1. Fare Result Card (`lib/src/presentation/widgets/fare_result_card.dart`)
**Role:** Displays a single fare calculation result.

- **Visual Structure:**
  - `Card` with colored border.
  - Column content: "BEST VALUE" badge (optional), Transport Mode Name, Price (Headline style), Passenger count.
- **Styling:**
  - Border color maps to `IndicatorLevel` (Green/Amber/Red).
  - "Recommended" items have thicker borders and a star icon.
  - Background is a low-opacity version of the status color.
- **Accessibility:**
  - **Excellent:** Uses a comprehensive `Semantics` label summarizing the entire card's content ("Fare estimate for X is Y...").

### 2. Map Selection Widget (`lib/src/presentation/widgets/map_selection_widget.dart`)
**Role:** Embedded map view in the Main Screen.

- **Visual Structure:**
  - `FlutterMap` with OpenStreetMap tiles.
  - Markers for Origin (Green) and Destination (Red).
  - Polyline for the route (Blue, width 4.0).
  - Floating "Clear Selection" button (bottom right).
- **Styling:**
  - Map takes full container space.
  - Standard marker icons.
- **UX Patterns:**
  - Camera automatically fits bounds of Origin/Destination.
  - Tap interaction allows selecting points directly on this widget too.

---

## Conclusion
The application currently adheres to a functional, "engineering-first" design approach. It uses standard Flutter Material widgets efficiently but lacks a distinct visual identity or "delight" factors.

**Key Improvement Opportunities:**
1.  **Visual Polish:** Move away from default Colors.blue/deepPurple to a custom color palette that reflects the "Filipino Commute" identity (perhaps jeepney-inspired colors).
2.  **Navigation:** Consider a BottomNavigationBar for switching between Calculator, Saved, and Reference screens instead of burying them in the AppBar.
3.  **Map Experience:** The map picker and embedded map could be unified or made more interactive with better transitions.
4.  **Feedback:** Add more micro-interactions (animations when fare is calculated, better loading states).
5.  **Typography:** The current typography is standard. Using a more modern font stack could improve readability.

This analysis serves as the baseline for the upcoming UI/UX redesign tasks.