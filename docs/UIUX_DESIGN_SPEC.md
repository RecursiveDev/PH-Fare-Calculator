# UI/UX Design Specification: PH Fare Calculator Redesign

## 1. Executive Summary
This design specification outlines the modernization of the PH Fare Calculator application. The goal is to transition from a generic "engineering-first" interface to a polished, user-centric experience that reflects the vibrancy of Philippine transportation while adhering to modern Material 3 guidelines.

**Key Design Pillars:**
*   **Legibility & Accessibility:** High-contrast typography and clear touch targets for commuters on the go.
*   **Identity:** A color palette inspired by the "Jeepney" aesthetic (Vivid Blue, Solar Yellow, Signal Red) balanced with clean white/dark surfaces.
*   **Fluidity:** Introduction of smooth transitions, bottom sheets for complex inputs, and unified navigation.

---

## 2. Global Design System

### 2.1. Color Palette
We will utilize a custom Material 3 color scheme generated from a core "Jeepney Blue" seed, with semantic functional colors.

**Light Mode:**
*   **Primary:** `0xFF0038A8` (Deep Blue) - Used for AppBars, primary buttons, active states.
*   **OnPrimary:** `0xFFFFFFFF` (White)
*   **Secondary:** `0xFFFCD116` (Sun Yellow) - Used for accents, floating action buttons, highlights.
*   **OnSecondary:** `0xFF1A1C1E` (Dark Grey) - For text on yellow backgrounds.
*   **Tertiary:** `0xFFCE1126` (Flag Red) - Used for destructive actions, warnings, or "High Traffic" indicators.
*   **Background:** `0xFFF8F9FA` (Off-white/Grey 50) - Reduces eye strain compared to pure white.
*   **Surface:** `0xFFFFFFFF` (White) - Card backgrounds.
*   **SurfaceVariant:** `0xFFE1E2EC` - Input fields, dividers.

**Dark Mode (High Contrast/Night):**
*   **Primary:** `0xFFB3C5FF` (Pastel Blue)
*   **Secondary:** `0xFFFDE26C` (Pastel Yellow)
*   **Background:** `0xFF121212` (Almost Black)
*   **Surface:** `0xFF1E1E1E` (Dark Grey)
*   **Error:** `0xFFCF6679` (Muted Red)

### 2.2. Typography
We will adopt a type scale that prioritizes readability.
*   **Font Family:** `Poppins` (Headings) and `Inter` or `Roboto` (Body).

| Style | Weight | Size | Usage |
| :--- | :--- | :--- | :--- |
| **Headline Large** | Bold | 32sp | Onboarding Titles |
| **Headline Medium** | SemiBold | 24sp | Section Headers, Total Fare Display |
| **Title Medium** | Medium | 16sp | Card Titles, App Bar Title |
| **Body Large** | Regular | 16sp | Standard Input Text, List Items |
| **Body Medium** | Regular | 14sp | Secondary Text, Descriptions |
| **Label Large** | Medium | 14sp | Buttons, Tabs |

### 2.3. Spacing & Shapes
*   **Grid Base:** 8dp
*   **Padding:**
    *   Screen Edge: 16dp (Mobile), 24dp (Tablet)
    *   Card Internal: 16dp
    *   Section Gap: 24dp
*   **Shapes (Border Radius):**
    *   **Cards:** 16dp (Soft modern look)
    *   **Buttons:** Stadium/Pill shape (Full rounded sides)
    *   **Input Fields:** 12dp (Consistent with cards)
    *   **Bottom Sheets:** Top-left/Top-right 28dp

### 2.4. Iconography
Use **Material Symbols Rounded** for a friendly, modern feel.
*   Navigation: `map`, `directions_bus`, `history`, `settings`
*   Actions: `search`, `my_location`, `close`, `done`

---

## 3. Component Design Patterns

### 3.1. Navigation
**New Pattern:** Implement a `BottomNavigationBar` for the main screen to separate concerns.
*   **Tabs:**
    1.  **Commute** (Calculator - Home)
    2.  **Saved** (History/Saved Routes)
    3.  **Reference** (Fare Matrices)
    4.  **Settings** (Config)

### 3.2. Inputs (Text Fields)
*   Style: `OutlineInputBorder` with `filled: true` (Fill color: SurfaceVariant/light grey).
*   Behavior: Floating labels.
*   Icons: Leading icons for context (e.g., `location_on`), Trailing icons for actions (e.g., `close` to clear, spinner for loading).

### 3.3. Cards
*   **Fare Result Card:**
    *   Elevation: 2 (Standard), 8 (Recommended).
    *   Layout: Transport icon left, details middle, price right.
    *   "Best Value" Tag: A pill-shaped badge on the top-right or overlaying the border.

### 3.4. Bottom Sheets
*   Replace complex Dialogs (like Passenger Count) with **Modal Bottom Sheets**.
*   Handle: Visible drag handle at top.

---

## 4. Screen-by-Screen Specifications

### 4.1. Main Screen (Dashboard)
*   **Layout:**
    *   **Header:** Standard AppBar is removed/simplified. The top section contains a "Greeting" or "Where to?" prompt.
    *   **Input Section:** Elevated Card container holding "Origin" and "Destination" fields stacked vertically with a "Swap" button connecting them.
    *   **Map Preview:** A rounded rectangle map preview (height: 200dp) below inputs. Tapping expands/opens picker.
    *   **Passenger & Options:** A horizontal scroll (Row) of chips or a single "Travel Options" bar showing "1 Passenger • Standard". Tapping opens a BottomSheet.
    *   **Calculate Button:** Full-width Floating Action Button (FAB) or anchored bottom button "Check Fares".
    *   **Results:** Draggable Scrollable Sheet or simply a list below the button.
*   **Animation:** Fare cards slide in and fade in staggered.

### 4.2. Map Picker Screen
*   **Layout:** Full screen map.
*   **Overlay:**
    *   **Top:** Transparent search bar (floating).
    *   **Center:** Animated Pin (bounces when moving map).
    *   **Bottom:** Floating Card showing "Selected Location: [Address]" with a "Confirm Location" primary button.
*   **Transition:** Fade in/out.

### 4.3. Offline Menu Screen (Deprecated/Moved)
*   *Design Decision:* This screen is redundant with the new BottomNavigation "Reference" tab.
*   *Redesign:* Incorporate into the "Reference" tab content.

### 4.4. Onboarding Screen
*   **Layout:** `PageView` with dots indicator.
*   **Slides:**
    1.  "Know Your Fare" (Illustration of Jeepney)
    2.  "Work Offline" (Illustration of Download/Phone)
    3.  "Language / Wika" (Language Selection Cards)
*   **Action:** "Get Started" button at the bottom.

### 4.5. Reference Screen (New Tab)
*   **Layout:** `DefaultTabController` with sticky headers.
*   **Tabs:** [Road] [Train] [Ferry] [Discount Info].
*   **Content:**
    *   Clean `ExpansionPanelList` for nested data.
    *   Search bar at top to filter matrices.

### 4.6. Saved Routes Screen (New Tab)
*   **Layout:** List of dismissible cards (Swipe to delete).
*   **Card:**
    *   Top: Origin -> Destination (Bold).
    *   Bottom: "3 Fare Options found" • Date.
    *   Tap action: Loads route into Calculator tab.

### 4.7. Settings Screen (New Tab)
*   **Layout:** Grouped List.
*   **Groups:** "Preferences" (Traffic, Passengers), "Appearance" (Dark Mode), "Data" (Clear Cache).
*   **Controls:** Use `Switch` for toggles, `SegmentedButton` for Traffic Factor (Low/Med/High).

### 4.8. Splash Screen
*   **Visual:** Centered App Logo.
*   **Animation:** Logo scales up slightly and fades out. Background ripples.

---

## 5. Widget Redesign Specifications

### 5.1. FareResultCard
*   **Old:** Boxy, colored borders, low opacity background.
*   **New:**
    *   **Container:** White surface, rounded corners (16dp).
    *   **Left Strip:** Colored vertical bar (4dp wide) indicating status (Green/Amber/Red).
    *   **Content Row:**
        *   **Icon:** Circular container with Transport Mode icon.
        *   **Info:** Mode Name (Bold), "Est. time" (if avail) or "10km".
        *   **Price:** Large text on right, aligned baseline.
    *   **Badges:** "Recommended" badge floats at the top right corner, overlapping the edge slightly.

### 5.2. MapSelectionWidget
*   **Old:** Rectangular 300px height.
*   **New:**
    *   **Shape:** Rounded corners (16dp), `ClipRRect`.
    *   **Interactivity:** "View Full Screen" button overlay in bottom right.
    *   **Visuals:** Custom map style (if possible) or clean OSM tiles. Markers should be custom SVG assets (Pin for Dest, Circle for Origin).

---