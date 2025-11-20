import 'package:flutter/material.dart';

import '../../core/hybrid_engine.dart';
import '../../models/fare_formula.dart';
import '../../services/fare_cache_service.dart';
import '../../services/osrm_api_service.dart';
import '../widgets/fare_result_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final HybridEngine _hybridEngine = HybridEngine(OsrmApiService());
  final FareCacheService _fareCacheService = FareCacheService();
  List<FareFormula> _availableFormulas = [];
  bool _isLoading = true;

  double? _fareResult;
  String? _errorMessage;
  bool _isAirportTaxi = false;
  final bool _isProvincial = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fareCacheService.seedDefaults();
    final formulas = await _fareCacheService.getAllFormulas();
    if (mounted) {
      setState(() {
        _availableFormulas = formulas;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fare Estimator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _originController,
              decoration: const InputDecoration(
                labelText: 'Origin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Text('Airport Taxi (Yellow)?'),
                const Spacer(),
                Switch(
                  value: _isAirportTaxi,
                  onChanged: (value) {
                    setState(() {
                      _isAirportTaxi = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _errorMessage = null;
                      });

                      // Hardcoded values for testing (Manila City Hall to Makati)
                      // TODO: Replace with actual coordinates from user input
                      const double originLat = 14.5995;
                      const double originLng = 120.9842;
                      const double destLat = 14.5547;
                      const double destLng = 121.0244;

                      // Select formula based on taxi type
                      final String targetSubType =
                          _isAirportTaxi ? 'Yellow Taxi' : 'White Taxi';

                      final FareFormula taxiFormula =
                          _availableFormulas.firstWhere(
                        (f) => f.subType == targetSubType,
                        orElse: () => FareFormula(
                          subType: 'Fallback $targetSubType',
                          baseFare: _isAirportTaxi ? 75.0 : 45.0,
                          perKmRate: _isAirportTaxi ? 20.0 : 13.50,
                        ),
                      );

                      try {
                  final fare = await _hybridEngine.calculateDynamicFare(
                    originLat: originLat,
                    originLng: originLng,
                    destLat: destLat,
                    destLng: destLng,
                    formula: taxiFormula,
                  );

                  setState(() {
                    _fareResult = fare;
                  });
                } catch (e) {
                  debugPrint('Error calculating fare: $e');
                  setState(() {
                    _fareResult = null;
                    _errorMessage =
                        'Could not calculate fare. Please check your route and try again.';
                  });
                }
              },
              child: const Text('Calculate Fare'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24.0),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (_fareResult != null) ...[
              const SizedBox(height: 24.0),
              FareResultCard(
                transportMode: _isAirportTaxi ? 'Yellow Taxi' : 'White Taxi',
                fare: _fareResult!,
                indicatorLevel: IndicatorLevel.standard,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
