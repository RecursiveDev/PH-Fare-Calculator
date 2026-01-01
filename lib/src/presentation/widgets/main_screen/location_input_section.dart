import 'package:flutter/material.dart';

import '../../../models/location.dart';

/// A card widget containing origin and destination input fields with autocomplete.
/// Input fields are limited to 2 lines with internal scrolling for longer addresses.
class LocationInputSection extends StatefulWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final bool isLoadingLocation;
  final Future<List<Location>> Function(String query, bool isOrigin)
  onSearchLocations;
  final ValueChanged<Location> onOriginSelected;
  final ValueChanged<Location> onDestinationSelected;
  final VoidCallback onSwapLocations;
  final VoidCallback onUseCurrentLocation;
  final void Function(bool isOrigin) onOpenMapPicker;

  const LocationInputSection({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.isLoadingLocation,
    required this.onSearchLocations,
    required this.onOriginSelected,
    required this.onDestinationSelected,
    required this.onSwapLocations,
    required this.onUseCurrentLocation,
    required this.onOpenMapPicker,
  });

  @override
  State<LocationInputSection> createState() => _LocationInputSectionState();
}

class _LocationInputSectionState extends State<LocationInputSection> {
  // Sizes for route indicator elements
  static const double _originCircleSize = 12;
  static const double _destinationIconSize = 16;
  static const double _fieldGap = 12;
  // Minimum height for input fields to ensure consistent layout
  static const double _minFieldHeight = 48;

  // Keys to measure actual field heights for dynamic indicator positioning
  final GlobalKey _originFieldKey = GlobalKey();
  final GlobalKey _destinationFieldKey = GlobalKey();
  
  // Current measured heights (updated after layout)
  double _originFieldHeight = _minFieldHeight;
  double _destinationFieldHeight = _minFieldHeight;

  @override
  void initState() {
    super.initState();
    // Measure field heights after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureFieldHeights();
    });
  }

  void _measureFieldHeights() {
    final originContext = _originFieldKey.currentContext;
    final destContext = _destinationFieldKey.currentContext;
    
    if (originContext != null && destContext != null) {
      final originBox = originContext.findRenderObject() as RenderBox?;
      final destBox = destContext.findRenderObject() as RenderBox?;
      
      if (originBox != null && destBox != null && originBox.hasSize && destBox.hasSize) {
        final newOriginHeight = originBox.size.height;
        final newDestHeight = destBox.size.height;
        
        if (newOriginHeight != _originFieldHeight || newDestHeight != _destinationFieldHeight) {
          setState(() {
            _originFieldHeight = newOriginHeight;
            _destinationFieldHeight = newDestHeight;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Schedule a measurement after this frame completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureFieldHeights();
    });

    // Calculate dynamic heights for route indicator
    final totalHeight = _originFieldHeight + _fieldGap + _destinationFieldHeight;
    
    // Line spans from center of origin field to center of destination field
    // minus half of each indicator's size
    final originCenter = _originFieldHeight / 2;
    final destCenter = _originFieldHeight + _fieldGap + (_destinationFieldHeight / 2);
    final lineTop = originCenter + (_originCircleSize / 2);
    final lineBottom = destCenter - (_destinationIconSize / 2);
    final lineHeight = (lineBottom - lineTop).clamp(0.0, double.infinity);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Indicator - dynamically positioned based on field heights
            SizedBox(
              height: totalHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Spacer to center origin circle with first field
                  SizedBox(height: (originCenter - (_originCircleSize / 2)).clamp(0.0, double.infinity)),
                  // Origin circle indicator
                  Container(
                    width: _originCircleSize,
                    height: _originCircleSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Connecting line - dynamically sized
                  Container(
                    width: 2,
                    height: lineHeight,
                    color: colorScheme.outlineVariant,
                  ),
                  // Destination pin indicator
                  Icon(
                    Icons.location_on,
                    size: _destinationIconSize,
                    color: colorScheme.tertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Input Fields
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Origin field with key for measurement
                  Container(
                    key: _originFieldKey,
                    child: _LocationField(
                      label: 'Origin',
                      controller: widget.originController,
                      isOrigin: true,
                      isLoadingLocation: widget.isLoadingLocation,
                      onSearchLocations: (query) =>
                          widget.onSearchLocations(query, true),
                      onLocationSelected: widget.onOriginSelected,
                      onUseCurrentLocation: widget.onUseCurrentLocation,
                      onOpenMapPicker: () => widget.onOpenMapPicker(true),
                    ),
                  ),
                  const SizedBox(height: _fieldGap),
                  // Destination field with key for measurement
                  Container(
                    key: _destinationFieldKey,
                    child: _LocationField(
                      label: 'Destination',
                      controller: widget.destinationController,
                      isOrigin: false,
                      isLoadingLocation: false,
                      onSearchLocations: (query) =>
                          widget.onSearchLocations(query, false),
                      onLocationSelected: widget.onDestinationSelected,
                      onUseCurrentLocation: null,
                      onOpenMapPicker: () => widget.onOpenMapPicker(false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Swap Button - centered vertically in the total height
            SizedBox(
              height: totalHeight,
              child: Center(
                child: _SwapButton(onSwap: widget.onSwapLocations),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swap button extracted for cleaner code and proper semantics
class _SwapButton extends StatelessWidget {
  final VoidCallback? onSwap;
  
  const _SwapButton({required this.onSwap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Semantics(
      label: 'Swap origin and destination',
      button: true,
      child: IconButton(
        icon: Icon(
          Icons.swap_vert_rounded,
          color: colorScheme.primary,
        ),
        onPressed: onSwap,
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer.withValues(
            alpha: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Internal widget for individual location input field with autocomplete.
/// Limited to 2 lines with internal scrolling for longer addresses.
class _LocationField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isOrigin;
  final bool isLoadingLocation;
  final Future<List<Location>> Function(String query) onSearchLocations;
  final ValueChanged<Location> onLocationSelected;
  final VoidCallback? onUseCurrentLocation;
  final VoidCallback onOpenMapPicker;

  const _LocationField({
    required this.label,
    required this.controller,
    required this.isOrigin,
    required this.isLoadingLocation,
    required this.onSearchLocations,
    required this.onLocationSelected,
    required this.onUseCurrentLocation,
    required this.onOpenMapPicker,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  final ValueNotifier<bool> _isSearching = ValueNotifier<bool>(false);
  double? _lastKnownWidth;
  
  /// Key used to force Autocomplete widget to rebuild when controller text changes externally
  /// (e.g., during swap operations). Incremented when we detect external changes.
  int _autocompleteRebuildKey = 0;
  
  /// Tracks the last known text to detect external changes
  String _lastKnownText = '';

  @override
  void initState() {
    super.initState();
    _lastKnownText = widget.controller.text;
    widget.controller.addListener(_onControllerTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerTextChanged);
    _isSearching.dispose();
    super.dispose();
  }
  
  /// Listener that detects external text changes (e.g., from swap operation)
  /// and forces the Autocomplete to rebuild with the new text.
  void _onControllerTextChanged() {
    if (widget.controller.text != _lastKnownText) {
      _lastKnownText = widget.controller.text;
      // Force Autocomplete to rebuild with new initialValue
      if (mounted) {
        setState(() {
          _autocompleteRebuildKey++;
        });
      }
    }
  }

  Future<List<Location>> _handleOptionsBuilder(String query) async {
    if (query.trim().isEmpty) {
      _isSearching.value = false;
      return const <Location>[];
    }

    // Set loading state before fetching
    _isSearching.value = true;

    try {
      final results = await widget.onSearchLocations(query);
      return results;
    } finally {
      // Delay clearing the loading state until after the current frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _isSearching.value = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use LayoutBuilder to capture width for autocomplete options
    return LayoutBuilder(
      builder: (context, constraints) {
        _lastKnownWidth = constraints.maxWidth;
        
        return Autocomplete<Location>(
          // Key changes when external text update detected, forcing rebuild
          key: ValueKey('${widget.isOrigin}_$_autocompleteRebuildKey'),
          displayStringForOption: (Location option) => option.name,
          initialValue: TextEditingValue(text: widget.controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) async {
            return _handleOptionsBuilder(textEditingValue.text);
          },
          onSelected: widget.onLocationSelected,
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return Semantics(
              label: 'Input for ${widget.label} location',
              textField: true,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isSearching,
                builder: (context, isSearching, child) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 2, // Limit to 2 lines
                    minLines: 1, // Start with 1 line for short text
                    keyboardType: TextInputType.streetAddress,
                    decoration: InputDecoration(
                      hintText: widget.label,
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
                          // Show loading indicator when searching for suggestions
                          if (isSearching)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                          // Show current location loading indicator (origin only)
                          else if (widget.isOrigin &&
                              widget.isLoadingLocation)
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
                          // Show current location button (origin only)
                          else if (widget.isOrigin &&
                              widget.onUseCurrentLocation != null)
                            IconButton(
                              icon: Icon(
                                Icons.my_location,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'Use my current location',
                              onPressed: widget.onUseCurrentLocation,
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.map_outlined,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            tooltip: 'Select from map',
                            onPressed: widget.onOpenMapPicker,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                  width: _lastKnownWidth ?? constraints.maxWidth,
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
}

