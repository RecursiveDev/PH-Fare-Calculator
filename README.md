# 🇵🇭 PH Fare Estimator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-blue.svg)](https://flutter.dev/)
[![Status](https://img.shields.io/badge/Status-Active%20Development-green.svg)]()

**PH Fare Estimator** is a cross-platform mobile application designed to help tourists, expats, and locals estimate public transport costs across the Philippines.

Unlike city-centric navigation apps, this tool focuses on **"How much?"** rather than "How to?". It solves the complex problem of Philippine geography by combining distance-based formulas (for roads) with static fare matrices (for trains and ferries).

## 🚀 Key Features

- **Nationwide Coverage:** Works in Metro Manila, Cebu, Davao, and rural provinces.
- **Hybrid Calculation Engine:**
  - **Dynamic:** Uses OSRM to calculate road distance for Jeeps, Taxis, and Buses.
  - **Static:** Uses Lookup Tables for fixed-price modes like MRT/LRT and Ferries.
- **Scam Detector:** Provides a "Fair Price Range" vs. "Overpriced" indicator to help tourists avoid getting ripped off.
- **Multi-Mode Comparison:** Compare the cost of a **Yellow Airport Taxi** (Premium) vs. a **White Taxi** (Regular) vs. **Jeepney** (Budget).
- **Offline Reference:** View saved routes and static fare cheat sheets without an internet connection.
- **Smart Search:** Disambiguates inputs (e.g., *San Jose, Antique* vs. *San Jose, Nueva Ecija*).

## 🛠 Tech Stack

- **Framework:** Flutter (v3.16+) & Dart
- **Routing API:** OSRM (Open Source Routing Machine) - *Configurable to switch to Mapbox/Google*.
- **Local Storage:** Hive (NoSQL) for caching and favorites.
- **HTTP Client:** `http` package

## 🧮 How It Works (The Hybrid Engine)

The Philippines has a fragmented transport pricing system. This app handles it using two methods:

### 1. Formula-Based (Road)
Used for **Jeepneys, Buses, Taxis, UV Express**.
> `Fare = Base Fare + ((OSRM Distance * 1.15) * Per KM Rate)`

*   **Why 1.15?** Public transport routes are rarely as direct as private car routes. We add a 15% variance factor to OSRM's output to approximate real-world travel.
*   **Provincial Variance:** A 20% variance is applied to the total fare when the "Provincial" toggle is enabled.

### 2. Matrix-Based (Fixed)
Used for **MRT, LRT, PNR, and Ferries**.
Distance formulas fail here (e.g., Rail distance ≠ Road distance).
> `Fare = Database lookup [Origin_Station] -> [Dest_Station]`

## 📱 Screenshots

*(Placeholder: Add screenshots of the Search Screen, Results Card, and Scam Detector UI here once built)*

| Search Screen | Results Card | Scam Detector |
|:---:|:---:|:---:|
| ![Search](docs/ss_search.png) | ![Results](docs/ss_results.png) | ![Warning](docs/ss_warning.png) |

## ⚙️ Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/ph-fare-estimator.git
    cd ph-fare-estimator
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Configure API (Optional)**
    By default, the app uses the public OSRM demo server. For production or heavy testing, update `lib/src/services/osrm_api_service.dart` with your own server URL.

4.  **Run the App**
    ```bash
    flutter run
    ```

## 📂 Project Structure

```
lib/
├── src/
│   ├── core/             # Logic for Fare Formulas & Constants
│   ├── models/           # Data Models (TransportMode, RouteResult)
│   ├── presentation/     # Screens & Widgets
│   │   ├── screens/      # Main Screen
│   │   └── widgets/      # Reusable UI Components
│   ├── services/         # Repositories & API Services (OSRM)
└── main.dart
```

## 🚧 Roadmap

- [ ] **Phase 1:** Basic UI & OSRM Integration (Jeep/Taxi Formulas).
- [ ] **Phase 2:** Integrate Yellow Taxi vs. White Taxi logic.
- [ ] **Phase 3:** Add Static Matrices for MRT-3, LRT-1, LRT-2.
- [ ] **Phase 4:** Offline Hive Caching.
- [ ] **Phase 5:** "Provincial Variance" Toggle (Settings).

## 🤝 Contributing

Contributions are welcome! especially if you have updated fare matrices for provincial ferries or buses.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

## ⚠️ Disclaimer

This app provides **estimates only**. Official fares are regulated by the LTFRB/DOTr and are subject to change without notice. This app is not affiliated with any government agency.

---
*Built with ❤️ for Philippine Commuters.*