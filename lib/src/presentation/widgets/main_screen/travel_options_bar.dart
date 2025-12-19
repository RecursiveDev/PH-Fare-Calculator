import 'package:flutter/material.dart';

import '../../../services/fare_comparison_service.dart';

/// A horizontal scrollable bar displaying travel options like passenger count,
/// discount indicator, sort criteria, and transport mode quick-access.
class TravelOptionsBar extends StatelessWidget {
  final int regularPassengers;
  final int discountedPassengers;
  final SortCriteria sortCriteria;
  final VoidCallback onPassengerTap;
  final ValueChanged<SortCriteria> onSortChanged;

  /// Number of enabled transport modes.
  final int enabledModesCount;

  /// Total number of available transport modes.
  final int totalModesCount;

  /// Callback when the transport modes button is tapped.
  final VoidCallback? onTransportModesTap;

  const TravelOptionsBar({
    super.key,
    required this.regularPassengers,
    required this.discountedPassengers,
    required this.sortCriteria,
    required this.onPassengerTap,
    required this.onSortChanged,
    this.enabledModesCount = 0,
    this.totalModesCount = 0,
    this.onTransportModesTap,
  });

  int get totalPassengers => regularPassengers + discountedPassengers;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              onPressed: onPassengerTap,
            ),
          ),
          const SizedBox(width: 8),
          // Discount indicator if applicable
          if (discountedPassengers > 0)
            Chip(
              avatar: Icon(
                Icons.discount_outlined,
                size: 16,
                color: colorScheme.secondary,
              ),
              label: Text(
                '$discountedPassengers Discounted',
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
          // Transport Modes Quick Access Chip
          if (onTransportModesTap != null)
            Semantics(
              label:
                  'Transport modes: $enabledModesCount of $totalModesCount enabled. Tap to change.',
              button: true,
              child: ActionChip(
                avatar: Badge(
                  label: Text(
                    '$enabledModesCount',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: enabledModesCount > 0
                      ? colorScheme.primary
                      : colorScheme.error,
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
                label: Text(
                  'Modes',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                backgroundColor: colorScheme.surfaceContainerLowest,
                side: BorderSide(
                  color: enabledModesCount > 0
                      ? colorScheme.outlineVariant
                      : colorScheme.error.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: onTransportModesTap,
              ),
            ),
          const SizedBox(width: 8),
          // Sort Chip
          Semantics(
            label:
                'Sort by: ${sortCriteria == SortCriteria.priceAsc ? 'Price Low to High' : 'Price High to Low'}',
            button: true,
            child: ActionChip(
              avatar: Icon(
                Icons.sort,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              label: Text(
                sortCriteria == SortCriteria.priceAsc ? 'Lowest' : 'Highest',
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
                final newCriteria = sortCriteria == SortCriteria.priceAsc
                    ? SortCriteria.priceDesc
                    : SortCriteria.priceAsc;
                onSortChanged(newCriteria);
              },
            ),
          ),
        ],
      ),
    );
  }
}
