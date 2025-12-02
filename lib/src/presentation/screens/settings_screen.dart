import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';
import '../../models/discount_type.dart';
import '../../models/fare_formula.dart';
import '../../models/transport_mode.dart';
import '../../repositories/fare_repository.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService? settingsService;

  const SettingsScreen({super.key, this.settingsService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;
  late final FareRepository _fareRepository;
  bool _isProvincialModeEnabled = false;
  bool _isHighContrastEnabled = false;
  TrafficFactor _trafficFactor = TrafficFactor.medium;
  DiscountType _discountType = DiscountType.standard;
  bool _isLoading = true;
  
  Set<String> _hiddenTransportModes = {};
  Map<String, List<FareFormula>> _groupedFormulas = {};

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? getIt<SettingsService>();
    _fareRepository = getIt<FareRepository>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provincialMode = await _settingsService.getProvincialMode();
    final trafficFactor = await _settingsService.getTrafficFactor();
    final highContrast = await _settingsService.getHighContrastEnabled();
    final discountType = await _settingsService.getUserDiscountType();
    final hiddenModes = await _settingsService.getHiddenTransportModes();
    final formulas = await _fareRepository.getAllFormulas();
    
    // Group formulas by mode
    final grouped = <String, List<FareFormula>>{};
    for (final formula in formulas) {
      if (!grouped.containsKey(formula.mode)) {
        grouped[formula.mode] = [];
      }
      grouped[formula.mode]!.add(formula);
    }
    
    if (mounted) {
      setState(() {
        _isProvincialModeEnabled = provincialMode;
        _isHighContrastEnabled = highContrast;
        _trafficFactor = trafficFactor;
        _discountType = discountType;
        _hiddenTransportModes = hiddenModes;
        _groupedFormulas = grouped;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.provincialModeTitle),
                  subtitle: Text(AppLocalizations.of(context)!.provincialModeSubtitle),
                  value: _isProvincialModeEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isProvincialModeEnabled = value;
                    });
                    await _settingsService.setProvincialMode(value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.highContrastModeTitle),
                  subtitle: Text(AppLocalizations.of(context)!.highContrastModeSubtitle),
                  value: _isHighContrastEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isHighContrastEnabled = value;
                    });
                    await _settingsService.setHighContrastEnabled(value);
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.trafficFactorTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.trafficFactorSubtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficLow),
                  subtitle: Text(AppLocalizations.of(context)!.trafficLowSubtitle),
                  value: TrafficFactor.low,
                  groupValue: _trafficFactor,
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficMedium),
                  subtitle: Text(AppLocalizations.of(context)!.trafficMediumSubtitle),
                  value: TrafficFactor.medium,
                  groupValue: _trafficFactor,
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficHigh),
                  subtitle: Text(AppLocalizations.of(context)!.trafficHighSubtitle),
                  value: TrafficFactor.high,
                  groupValue: _trafficFactor,
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Passenger Type',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Select your passenger type to apply eligible discounts (20% off for Student, Senior, PWD)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                RadioListTile<DiscountType>(
                  title: Text(DiscountType.standard.displayName),
                  subtitle: const Text('No discount'),
                  value: DiscountType.standard,
                  groupValue: _discountType,
                  onChanged: (DiscountType? value) async {
                    if (value != null) {
                      setState(() {
                        _discountType = value;
                      });
                      await _settingsService.setUserDiscountType(value);
                    }
                  },
                ),
                RadioListTile<DiscountType>(
                  title: Text(DiscountType.discounted.displayName),
                  subtitle: const Text('20% discount (RA 11314, RA 9994, RA 7277)'),
                  value: DiscountType.discounted,
                  groupValue: _discountType,
                  onChanged: (DiscountType? value) async {
                    if (value != null) {
                      setState(() {
                        _discountType = value;
                      });
                      await _settingsService.setUserDiscountType(value);
                    }
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Transport Modes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Learn about Philippine transport options and select which modes to include in calculations',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ..._buildTransportModeDescriptions(),
                const SizedBox(height: 16.0),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                  child: Text(
                    'Available Transport Options',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ..._buildTransportModeToggles(),
              ],
            ),
    );
  }

  List<Widget> _buildTransportModeDescriptions() {
    final widgets = <Widget>[];
    
    // Get unique transport modes from formulas
    final uniqueModes = _groupedFormulas.keys.toSet();
    
    for (final modeStr in uniqueModes) {
      try {
        final mode = TransportMode.fromString(modeStr);
        
        widgets.add(
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForMode(mode),
                        size: 20,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mode.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        // Skip if mode string doesn't match enum
        continue;
      }
    }
    
    return widgets;
  }

  IconData _getIconForMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.jeepney:
        return Icons.directions_bus;
      case TransportMode.bus:
        return Icons.airport_shuttle;
      case TransportMode.taxi:
        return Icons.local_taxi;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.ferry:
        return Icons.directions_boat;
      case TransportMode.tricycle:
        return Icons.pedal_bike;
      case TransportMode.uvExpress:
        return Icons.local_shipping;
    }
  }

  List<Widget> _buildTransportModeToggles() {
    final widgets = <Widget>[];
    
    // Sort modes alphabetically for consistent display
    final sortedModes = _groupedFormulas.keys.toList()..sort();
    
    for (final mode in sortedModes) {
      final formulas = _groupedFormulas[mode]!;
      
      // Add mode header
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
          child: Text(
            mode,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ),
      );
      
      // Add subtype toggles
      for (final formula in formulas) {
        final modeSubTypeKey = '${formula.mode}::${formula.subType}';
        final isHidden = _hiddenTransportModes.contains(modeSubTypeKey);
        
        widgets.add(
          SwitchListTile(
            title: Text('  ${formula.subType}'),
            subtitle: formula.notes != null && formula.notes!.isNotEmpty
                ? Text(
                    '  ${formula.notes}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            value: !isHidden,
            onChanged: (bool value) async {
              final shouldHide = !value;
              await _settingsService.toggleTransportMode(modeSubTypeKey, shouldHide);
              
              setState(() {
                if (shouldHide) {
                  _hiddenTransportModes.add(modeSubTypeKey);
                } else {
                  _hiddenTransportModes.remove(modeSubTypeKey);
                }
              });
            },
            contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
          ),
        );
      }
    }
    
    return widgets;
  }
}