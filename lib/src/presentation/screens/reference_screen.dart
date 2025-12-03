import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../src/models/fare_formula.dart';
import '../../../src/models/static_fare.dart';

class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  List<FareFormula> _roadFormulas = [];
  Map<String, List<StaticFare>> _trainMatrix = {};
  List<StaticFare> _ferryRoutes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    try {
      // Load road formulas
      final formulasJson = await rootBundle.loadString('assets/data/fare_formulas.json');
      final formulasData = json.decode(formulasJson);
      _roadFormulas = (formulasData['road'] as List)
          .map((json) => FareFormula.fromJson(json))
          .toList();

      // Load train matrix
      final trainJson = await rootBundle.loadString('assets/data/train_matrix.json');
      final trainData = json.decode(trainJson) as Map<String, dynamic>;
      _trainMatrix = trainData.map((key, value) {
        final routes = (value as List)
            .map((json) => StaticFare.fromJson(json))
            .toList();
        return MapEntry(key, routes);
      });

      // Load ferry routes
      final ferryJson = await rootBundle.loadString('assets/data/ferry_matrix.json');
      final ferryData = json.decode(ferryJson);
      _ferryRoutes = (ferryData['routes'] as List)
          .map((json) => StaticFare.fromJson(json))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reference data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare Reference Guide'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildDiscountInfoSection(),
                    const SizedBox(height: 24.0),
                    _buildRoadTransportSection(),
                    const SizedBox(height: 24.0),
                    _buildTrainSection(),
                    const SizedBox(height: 24.0),
                    _buildFerrySection(),
                  ],
                ),
    );
  }

  Widget _buildDiscountInfoSection() {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Discount Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildDiscountRow(
              icon: Icons.school,
              category: 'Students',
              discount: '20% off base fare',
            ),
            const SizedBox(height: 8),
            _buildDiscountRow(
              icon: Icons.elderly,
              category: 'Senior Citizens (60+)',
              discount: '20% off base fare',
            ),
            const SizedBox(height: 8),
            _buildDiscountRow(
              icon: Icons.accessible,
              category: 'Persons with Disabilities (PWD)',
              discount: '20% off base fare',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[700]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valid ID required for discount eligibility. Discount applies to most public transport modes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountRow({
    required IconData icon,
    required String category,
    required String discount,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[700]!),
          ),
          child: Text(
            discount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoadTransportSection() {
    // Group formulas by mode
    final groupedFormulas = <String, List<FareFormula>>{};
    for (final formula in _roadFormulas) {
      groupedFormulas.putIfAbsent(formula.mode, () => []).add(formula);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Road Transport Fares'),
        ...groupedFormulas.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ...entry.value.asMap().entries.map((formulaEntry) {
                      final formula = formulaEntry.value;
                      final isLast = formulaEntry.key == entry.value.length - 1;
                      return Column(
                        children: [
                          _FareFormulaRow(formula: formula),
                          if (!isLast) const Divider(height: 16),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrainSection() {
    // Group train routes by line name for card-based display
    final groupedTrains = <String, List<StaticFare>>{};
    for (final entry in _trainMatrix.entries) {
      groupedTrains[entry.key] = entry.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Train/Rail Fares'),
        ...groupedTrains.entries.map((entry) {
          final lineName = entry.key;
          final routes = entry.value;
          
          // Get unique origins for summary
          final uniqueOrigins = routes.map((r) => r.origin).toSet().toList();
          
          // Find max fare
          final maxFare = routes.map((r) => r.price).reduce((a, b) => a > b ? a : b);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lineName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _FareDetail(
                            label: 'Max Fare',
                            value: '₱${maxFare.toStringAsFixed(2)}',
                          ),
                        ),
                        Expanded(
                          child: _FareDetail(
                            label: 'Stations',
                            value: '${uniqueOrigins.length}',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'Sample Routes:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...routes.take(10).map((route) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${route.origin} → ${route.destination}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '₱${route.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (routes.length > 10)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '... and ${routes.length - 10} more routes',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFerrySection() {
    // Group ferry routes by origin
    final groupedFerries = <String, List<StaticFare>>{};
    for (final route in _ferryRoutes) {
      groupedFerries.putIfAbsent(route.origin, () => []).add(route);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Ferry Routes'),
        ...groupedFerries.entries.map((entry) {
          final origin = entry.key;
          final routes = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 2,
              child: ExpansionTile(
                title: Text(
                  'From $origin',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${routes.length} destination(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: routes.map((route) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  route.destination,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              if (route.operator != null)
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    route.operator!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              Text(
                                '₱${route.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _FareFormulaRow extends StatelessWidget {
  final FareFormula formula;

  const _FareFormulaRow({required this.formula});

  @override
  Widget build(BuildContext context) {
    final hasBaseFare = formula.baseFare > 0;
    final hasPerKm = formula.perKmRate > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use column layout for narrow screens, wrap for wider screens
        final useColumnLayout = constraints.maxWidth < 300;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formula.subType,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            if (hasBaseFare || hasPerKm)
              useColumnLayout
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasBaseFare)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: _FareDetail(
                              label: 'Base',
                              value: '₱${formula.baseFare.toStringAsFixed(2)}',
                            ),
                          ),
                        if (hasPerKm)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: _FareDetail(
                              label: 'Per km',
                              value: '₱${formula.perKmRate.toStringAsFixed(2)}',
                            ),
                          ),
                        if (formula.minimumFare != null)
                          _FareDetail(
                            label: 'Min',
                            value: '₱${formula.minimumFare!.toStringAsFixed(2)}',
                          ),
                      ],
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (hasBaseFare)
                          _FareDetail(
                            label: 'Base',
                            value: '₱${formula.baseFare.toStringAsFixed(2)}',
                          ),
                        if (hasPerKm)
                          _FareDetail(
                            label: 'Per km',
                            value: '₱${formula.perKmRate.toStringAsFixed(2)}',
                          ),
                        if (formula.minimumFare != null)
                          _FareDetail(
                            label: 'Min',
                            value: '₱${formula.minimumFare!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
            if (formula.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                formula.notes!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FareDetail extends StatelessWidget {
  final String label;
  final String value;

  const _FareDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}