import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../core/errors/failures.dart';
import '../../core/hybrid_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../models/discount_type.dart';
import '../../models/fare_formula.dart';
import '../../models/fare_result.dart';
import '../../models/location.dart';
import '../../models/saved_route.dart';
import '../../models/transport_mode.dart';
import '../../repositories/fare_repository.dart';
import '../../services/fare_comparison_service.dart';
import '../../services/geocoding/geocoding_service.dart';
import '../../services/routing/routing_service.dart';
import '../../services/settings_service.dart';
import '../widgets/fare_result_card.dart';
import '../widgets/map_selection_widget.dart';
import 'map_picker_screen.dart';
import 'offline_menu_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Geocoding state
  final GeocodingService _geocodingService = getIt<GeocodingService>();
  Location? _originLocation;
  Location? _destinationLocation;

  // Engine and Data state
  final HybridEngine _hybridEngine = getIt<HybridEngine>();
  final FareRepository _fareRepository = getIt<FareRepository>();
  final RoutingService _routingService = getIt<RoutingService>();
  final SettingsService _settingsService = getIt<SettingsService>();
  final FareComparisonService _fareComparisonService =
      getIt<FareComparisonService>();
  List<FareFormula> _availableFormulas = [];
  bool _isLoading = true;
  bool _isCalculating = false;

  // Map state
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
  List<LatLng> _routePoints = [];

  // Debounce timers
  Timer? _originDebounceTimer;
  Timer? _destinationDebounceTimer;

  // UI state
  List<FareResult> _fareResults = [];
  String? _errorMessage;
  bool _isLoadingLocation = false;
  int _passengerCount = 1;
  int _regularPassengers = 1;
  int _discountedPassengers = 0;
  SortCriteria _sortCriteria = SortCriteria.priceAsc;

  // Text controllers
  final TextEditingController _originTextController = TextEditingController();
  final TextEditingController _destinationTextController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _originDebounceTimer?.cancel();
    _destinationDebounceTimer?.cancel();
    _originTextController.dispose();
    _destinationTextController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final formulas = await _fareRepository.getAllFormulas();
    final lastLocation = await _settingsService.getLastLocation();
    final hasSetDiscountType = await _settingsService.hasSetDiscountType();
    final userDiscountType = await _settingsService.getUserDiscountType();

    if (mounted) {
      setState(() {
        _availableFormulas = formulas;
        _isLoading = false;

        if (lastLocation != null) {
          _originLocation = lastLocation;
          _originLatLng = LatLng(lastLocation.latitude, lastLocation.longitude);
          _originTextController.text = lastLocation.name;
        }

        if (userDiscountType == DiscountType.discounted &&
            _passengerCount == 1) {
          _regularPassengers = 0;
          _discountedPassengers = 1;
        } else {
          _regularPassengers = 1;
          _discountedPassengers = 0;
        }
      });

      if (!hasSetDiscountType) {
        _showFirstTimePassengerTypePrompt();
      }
    }
  }

  Future<void> _showFirstTimePassengerTypePrompt() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to PH Fare Calculator',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select your passenger type for accurate fare estimates:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _PassengerTypeCard(
                          icon: Icons.person,
                          label: 'Regular',
                          description: 'Standard fare',
                          onTap: () async {
                            await _settingsService.setUserDiscountType(
                              DiscountType.standard,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PassengerTypeCard(
                          icon: Icons.school,
                          label: 'Discounted',
                          description: 'Student/Senior/PWD',
                          onTap: () async {
                            await _settingsService.setUserDiscountType(
                              DiscountType.discounted,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This can be changed later in Settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Modern App Bar
            _buildModernAppBar(colorScheme, textTheme),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Location Input Card
                    _buildLocationInputCard(colorScheme, textTheme),
                    const SizedBox(height: 16),
                    // Travel Options Row
                    _buildTravelOptionsRow(colorScheme, textTheme),
                    const SizedBox(height: 16),
                    // Map Preview
                    _buildMapPreview(colorScheme),
                    const SizedBox(height: 24),
                    // Calculate Button
                    _buildCalculateButton(colorScheme),
                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorMessage(colorScheme),
                    ],
                    // Fare Results
                    if (_fareResults.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildResultsHeader(colorScheme, textTheme),
                      const SizedBox(height: 16),
                      _buildGroupedFareResults(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.fareEstimatorTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Where are you going today?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Open offline reference menu',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.menu_book_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Offline Reference',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineMenuScreen(),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Open settings',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Indicator
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 48,
                      color: colorScheme.outlineVariant,
                    ),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.tertiary,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Input Fields
                Expanded(
                  child: Column(
                    children: [
                      _buildLocationField(
                        label: AppLocalizations.of(context)!.originLabel,
                        controller: _originTextController,
                        isOrigin: true,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildLocationField(
                        label: AppLocalizations.of(context)!.destinationLabel,
                        controller: _destinationTextController,
                        isOrigin: false,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
                // Swap Button
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 20),
                  child: Semantics(
                    label: 'Swap origin and destination',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        Icons.swap_vert_rounded,
                        color: colorScheme.primary,
                      ),
                      onPressed: _swapLocations,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required TextEditingController controller,
    required bool isOrigin,
    required ColorScheme colorScheme,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Location>(
          displayStringForOption: (Location option) => option.name,
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.trim().isEmpty) {
              return const Iterable<Location>.empty();
            }

            final debounceTimer = isOrigin
                ? _originDebounceTimer
                : _destinationDebounceTimer;
            debounceTimer?.cancel();

            final completer = Completer<List<Location>>();

            final newTimer = Timer(const Duration(milliseconds: 800), () async {
              try {
                final locations = await _geocodingService.getLocations(
                  textEditingValue.text,
                );
                if (!completer.isCompleted) {
                  completer.complete(locations);
                }
              } catch (e) {
                if (!completer.isCompleted) {
                  completer.complete([]);
                }
              }
            });

            if (isOrigin) {
              _originDebounceTimer = newTimer;
            } else {
              _destinationDebounceTimer = newTimer;
            }

            return completer.future;
          },
          onSelected: (Location location) {
            if (isOrigin) {
              setState(() {
                _originLocation = location;
                _originLatLng = LatLng(location.latitude, location.longitude);
                _resetResult();
              });
            } else {
              setState(() {
                _destinationLocation = location;
                _destinationLatLng = LatLng(
                  location.latitude,
                  location.longitude,
                );
                _resetResult();
              });
            }
            if (_originLocation != null && _destinationLocation != null) {
              _calculateRoute();
            }
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                // Sync controller text
                if (isOrigin && controller.text != textEditingController.text) {
                  textEditingController.text = controller.text;
                }
                return Semantics(
                  label: 'Input for $label location',
                  textField: true,
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: label,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOrigin && _isLoadingLocation)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (isOrigin)
                            IconButton(
                              icon: Icon(
                                Icons.my_location,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'Use my current location',
                              onPressed: () => _useCurrentLocation(
                                textEditingController,
                                (location) {
                                  setState(() {
                                    _originLocation = location;
                                    _originLatLng = LatLng(
                                      location.latitude,
                                      location.longitude,
                                    );
                                    _originTextController.text = location.name;
                                    _resetResult();
                                  });
                                  if (_destinationLocation != null) {
                                    _calculateRoute();
                                  }
                                },
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.map_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            tooltip: 'Select from map',
                            onPressed: () => _openMapPicker(
                              isOrigin,
                              textEditingController,
                              (location) {
                                if (isOrigin) {
                                  setState(() {
                                    _originLocation = location;
                                    _originLatLng = LatLng(
                                      location.latitude,
                                      location.longitude,
                                    );
                                    _originTextController.text = location.name;
                                    _resetResult();
                                  });
                                } else {
                                  setState(() {
                                    _destinationLocation = location;
                                    _destinationLatLng = LatLng(
                                      location.latitude,
                                      location.longitude,
                                    );
                                    _destinationTextController.text =
                                        location.name;
                                    _resetResult();
                                  });
                                }
                                if (_originLocation != null &&
                                    _destinationLocation != null) {
                                  _calculateRoute();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Location option = options.elementAt(index);
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          option.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTravelOptionsRow(ColorScheme colorScheme, TextTheme textTheme) {
    final totalPassengers = _regularPassengers + _discountedPassengers;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Passenger Count Chip
          Semantics(
            label: 'Passenger count: $totalPassengers. Tap to change.',
            button: true,
            child: ActionChip(
              avatar: Icon(
                Icons.people_outline,
                size: 18,
                color: colorScheme.primary,
              ),
              label: Text(
                '$totalPassengers Passenger${totalPassengers > 1 ? 's' : ''}',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerLowest,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: _showPassengerBottomSheet,
            ),
          ),
          const SizedBox(width: 8),
          // Discount indicator if applicable
          if (_discountedPassengers > 0)
            Chip(
              avatar: Icon(
                Icons.discount_outlined,
                size: 16,
                color: colorScheme.secondary,
              ),
              label: Text(
                '$_discountedPassengers Discounted',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              backgroundColor: colorScheme.secondaryContainer,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          const SizedBox(width: 8),
          // Sort Chip
          Semantics(
            label:
                'Sort by: ${_sortCriteria == SortCriteria.priceAsc ? 'Price Low to High' : 'Price High to Low'}',
            button: true,
            child: ActionChip(
              avatar: Icon(
                Icons.sort,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              label: Text(
                _sortCriteria == SortCriteria.priceAsc ? 'Lowest' : 'Highest',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerLowest,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () {
                setState(() {
                  _sortCriteria = _sortCriteria == SortCriteria.priceAsc
                      ? SortCriteria.priceDesc
                      : SortCriteria.priceAsc;
                  if (_fareResults.isNotEmpty) {
                    _fareResults = _fareComparisonService.sortFares(
                      _fareResults,
                      _sortCriteria,
                    );
                    _updateRecommendedFlag();
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPassengerBottomSheet() async {
    int tempRegular = _regularPassengers;
    int tempDiscounted = _discountedPassengers;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Passenger Details',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Regular Passengers
                  _buildPassengerCounter(
                    label: 'Regular Passengers',
                    subtitle: 'Standard fare rate',
                    count: tempRegular,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onDecrement: tempRegular > 0
                        ? () => setSheetState(() => tempRegular--)
                        : null,
                    onIncrement: tempRegular < 99
                        ? () => setSheetState(() => tempRegular++)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Discounted Passengers
                  _buildPassengerCounter(
                    label: 'Discounted Passengers',
                    subtitle: 'Student/Senior/PWD - 20% off',
                    count: tempDiscounted,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onDecrement: tempDiscounted > 0
                        ? () => setSheetState(() => tempDiscounted--)
                        : null,
                    onIncrement: tempDiscounted < 99
                        ? () => setSheetState(() => tempDiscounted++)
                        : null,
                  ),
                  const SizedBox(height: 24),
                  // Total Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Total: ${tempRegular + tempDiscounted} passenger(s)',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (tempRegular + tempDiscounted) > 0
                              ? () {
                                  setState(() {
                                    _regularPassengers = tempRegular;
                                    _discountedPassengers = tempDiscounted;
                                    _passengerCount =
                                        tempRegular + tempDiscounted;
                                    if (_originLocation != null &&
                                        _destinationLocation != null) {
                                      _calculateFare();
                                    }
                                  });
                                  Navigator.of(context).pop();
                                }
                              : null,
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPassengerCounter({
    required String label,
    required String subtitle,
    required int count,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    VoidCallback? onDecrement,
    VoidCallback? onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Counter Controls
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    color: onDecrement != null
                        ? colorScheme.primary
                        : colorScheme.outline,
                    size: 20,
                  ),
                  onPressed: onDecrement,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: onIncrement != null
                        ? colorScheme.primary
                        : colorScheme.outline,
                    size: 20,
                  ),
                  onPressed: onIncrement,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            MapSelectionWidget(
              origin: _originLatLng,
              destination: _destinationLatLng,
              routePoints: _routePoints,
            ),
            // Overlay gradient for better visibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton(ColorScheme colorScheme) {
    final canCalculate =
        !_isLoading &&
        !_isCalculating &&
        _originLocation != null &&
        _destinationLocation != null;

    return Semantics(
      label: 'Calculate Fare based on selected origin and destination',
      button: true,
      enabled: canCalculate,
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: canCalculate ? _calculateFare : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isCalculating
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calculate_outlined),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.calculateFareButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Fare Options',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Semantics(
          label: 'Save this route for later',
          button: true,
          child: TextButton.icon(
            onPressed: _saveRoute,
            icon: Icon(
              Icons.bookmark_add_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            label: Text(
              AppLocalizations.of(context)!.saveRouteButton,
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedFareResults() {
    final groupedResults = _fareComparisonService.groupFaresByMode(
      _fareResults,
    );

    final sortedGroups = groupedResults.entries.toList();
    if (_sortCriteria == SortCriteria.priceAsc) {
      sortedGroups.sort((a, b) {
        final aMin = a.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a < b ? a : b);
        final bMin = b.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a < b ? a : b);
        return aMin.compareTo(bMin);
      });
    } else if (_sortCriteria == SortCriteria.priceDesc) {
      sortedGroups.sort((a, b) {
        final aMax = a.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a > b ? a : b);
        final bMax = b.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a > b ? a : b);
        return bMax.compareTo(aMax);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedGroups.asMap().entries.map((entry) {
        final index = entry.key;
        final groupEntry = entry.value;
        final mode = groupEntry.key;
        final fares = groupEntry.value;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTransportModeHeader(mode),
              const SizedBox(height: 8),
              ...fares.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FareResultCard(
                    transportMode: result.transportMode,
                    fare: result.totalFare,
                    indicatorLevel: result.indicatorLevel,
                    isRecommended: result.isRecommended,
                    passengerCount: result.passengerCount,
                    totalFare: result.totalFare,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransportModeHeader(TransportMode mode) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransportModeIcon(mode),
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            mode.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransportModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.jeepney:
        return Icons.directions_bus;
      case TransportMode.bus:
        return Icons.directions_bus_filled;
      case TransportMode.taxi:
        return Icons.local_taxi;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.ferry:
        return Icons.directions_boat;
      case TransportMode.tricycle:
        return Icons.electric_rickshaw;
      case TransportMode.uvExpress:
        return Icons.airport_shuttle;
      case TransportMode.van:
        return Icons.airport_shuttle;
      case TransportMode.motorcycle:
        return Icons.two_wheeler;
      case TransportMode.edsaCarousel:
        return Icons.directions_bus;
      case TransportMode.pedicab:
        return Icons.pedal_bike;
      case TransportMode.kuliglig:
        return Icons.agriculture;
    }
  }

  void _swapLocations() {
    if (_originLocation == null && _destinationLocation == null) return;

    setState(() {
      final tempLocation = _originLocation;
      final tempLatLng = _originLatLng;
      final tempText = _originTextController.text;

      _originLocation = _destinationLocation;
      _originLatLng = _destinationLatLng;
      _originTextController.text = _destinationTextController.text;

      _destinationLocation = tempLocation;
      _destinationLatLng = tempLatLng;
      _destinationTextController.text = tempText;

      _resetResult();
    });

    if (_originLocation != null && _destinationLocation != null) {
      _calculateRoute();
    }
  }

  void _updateRecommendedFlag() {
    if (_fareResults.isEmpty) return;

    _fareResults = _fareResults.map((result) {
      return FareResult(
        transportMode: result.transportMode,
        fare: result.fare,
        indicatorLevel: result.indicatorLevel,
        isRecommended: false,
        passengerCount: result.passengerCount,
        totalFare: result.totalFare,
      );
    }).toList();

    _fareResults[0] = FareResult(
      transportMode: _fareResults[0].transportMode,
      fare: _fareResults[0].fare,
      indicatorLevel: _fareResults[0].indicatorLevel,
      isRecommended: true,
      passengerCount: _fareResults[0].passengerCount,
      totalFare: _fareResults[0].totalFare,
    );
  }

  Future<void> _openMapPicker(
    bool isOrigin,
    TextEditingController controller,
    ValueChanged<Location> onSelected,
  ) async {
    final initialLocation = isOrigin
        ? _originLatLng
        : (_destinationLatLng ?? _originLatLng);
    final title = isOrigin ? 'Select Origin' : 'Select Destination';

    final LatLng? selectedLatLng = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPickerScreen(initialLocation: initialLocation, title: title),
      ),
    );

    if (selectedLatLng != null) {
      try {
        setState(() {
          _isLoadingLocation = true;
          _errorMessage = null;
        });

        final location = await _geocodingService.getAddressFromLatLng(
          selectedLatLng.latitude,
          selectedLatLng.longitude,
        );

        if (mounted) {
          controller.text = location.name;
          onSelected(location);

          setState(() {
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        if (mounted) {
          String errorMsg = 'Failed to get address for selected location.';

          if (e is Failure) {
            errorMsg = e.message;
          }

          setState(() {
            _isLoadingLocation = false;
            _errorMessage = errorMsg;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _resetResult() {
    if (_fareResults.isNotEmpty ||
        _errorMessage != null ||
        _routePoints.isNotEmpty) {
      setState(() {
        _fareResults = [];
        _errorMessage = null;
        _routePoints = [];
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_originLocation == null || _destinationLocation == null) {
      return;
    }

    try {
      final routeResult = await _routingService.getRoute(
        _originLocation!.latitude,
        _originLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      setState(() {
        _routePoints = routeResult.geometry;
      });
    } catch (e) {
      debugPrint('Error calculating route: $e');
    }
  }

  Future<void> _saveRoute() async {
    if (_originLocation == null ||
        _destinationLocation == null ||
        _fareResults.isEmpty) {
      return;
    }

    final route = SavedRoute(
      origin: _originLocation!.name,
      destination: _destinationLocation!.name,
      fareResults: _fareResults,
      timestamp: DateTime.now(),
    );

    await _fareRepository.saveRoute(route);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.routeSavedMessage),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _calculateFare() async {
    setState(() {
      _errorMessage = null;
      _fareResults = [];
      _isCalculating = true;
    });

    try {
      if (_originLocation != null) {
        await _settingsService.saveLastLocation(_originLocation!);
      }

      final List<FareResult> results = [];
      final trafficFactor = await _settingsService.getTrafficFactor();
      final hiddenModes = await _settingsService.getHiddenTransportModes();

      final visibleFormulas = _availableFormulas.where((formula) {
        final modeSubTypeKey = '${formula.mode}::${formula.subType}';
        return !hiddenModes.contains(modeSubTypeKey);
      }).toList();

      if (visibleFormulas.isEmpty) {
        setState(() {
          _errorMessage =
              'No transport modes enabled. Please enable at least one mode in Settings.';
          _isCalculating = false;
        });
        return;
      }

      for (final formula in visibleFormulas) {
        if (formula.baseFare == 0.0 && formula.perKmRate == 0.0) {
          debugPrint(
            'Skipping invalid formula for ${formula.mode} (${formula.subType})',
          );
          continue;
        }

        final fare = await _hybridEngine.calculateDynamicFare(
          originLat: _originLocation!.latitude,
          originLng: _originLocation!.longitude,
          destLat: _destinationLocation!.latitude,
          destLng: _destinationLocation!.longitude,
          formula: formula,
          passengerCount: _passengerCount,
          regularCount: _regularPassengers,
          discountedCount: _discountedPassengers,
        );

        final indicator = formula.mode == 'Taxi'
            ? _hybridEngine.getIndicatorLevel(trafficFactor.name)
            : IndicatorLevel.standard;

        final totalFare = fare;

        results.add(
          FareResult(
            transportMode: '${formula.mode} (${formula.subType})',
            fare: fare,
            indicatorLevel: indicator,
            isRecommended: false,
            passengerCount: _passengerCount,
            totalFare: totalFare,
          ),
        );
      }

      final sortedResults = _fareComparisonService.sortFares(
        results,
        _sortCriteria,
      );

      if (sortedResults.isNotEmpty) {
        sortedResults[0] = FareResult(
          transportMode: sortedResults[0].transportMode,
          fare: sortedResults[0].fare,
          indicatorLevel: sortedResults[0].indicatorLevel,
          isRecommended: true,
          passengerCount: sortedResults[0].passengerCount,
          totalFare: sortedResults[0].totalFare,
        );
      }

      setState(() {
        _fareResults = sortedResults;
        _isCalculating = false;
      });
    } catch (e) {
      debugPrint('Error calculating fare: $e');
      String msg =
          'Could not calculate fare. Please check your route and try again.';
      if (e is Failure) {
        msg = e.message;
      }

      setState(() {
        _fareResults = [];
        _errorMessage = msg;
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocation(
    TextEditingController controller,
    ValueChanged<Location> onSelected,
  ) async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final location = await _geocodingService.getCurrentLocationAddress();

      if (mounted) {
        controller.text = location.name;
        onSelected(location);

        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to get current location.';

        if (e is Failure) {
          errorMsg = e.message;
        }

        setState(() {
          _isLoadingLocation = false;
          _errorMessage = errorMsg;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

/// Helper widget for passenger type selection cards
class _PassengerTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _PassengerTypeCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
