import 'package:flutter/material.dart';
import '../../models/fare_result.dart';

class FareResultCard extends StatelessWidget {
  final String transportMode;
  final double fare;
  final IndicatorLevel indicatorLevel;
  final bool isRecommended;
  final int passengerCount;
  final double totalFare;

  const FareResultCard({
    super.key,
    required this.transportMode,
    required this.fare,
    required this.indicatorLevel,
    this.isRecommended = false,
    this.passengerCount = 1,
    required this.totalFare,
  });

  Color _getColor(IndicatorLevel level) {
    switch (level) {
      case IndicatorLevel.standard:
        return Colors.green;
      case IndicatorLevel.peak:
        return Colors.amber;
      case IndicatorLevel.touristTrap:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(indicatorLevel);
    final displayFare = totalFare;
    final hasMultiplePassengers = passengerCount > 1;

    return Semantics(
      label:
          'Fare estimate for $transportMode is ${displayFare.toStringAsFixed(2)} pesos${hasMultiplePassengers ? ' for $passengerCount passengers' : ''}. Traffic level: ${indicatorLevel.name}.${isRecommended ? ' Best Value option.' : ''}',
      child: Card(
        elevation: isRecommended ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: color, width: isRecommended ? 3.0 : 2.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRecommended) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'BEST VALUE',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.star, color: Colors.amber[700], size: 20),
                  ],
                ),
                const SizedBox(height: 12.0),
              ],
              Text(
                transportMode,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                '₱ ${displayFare.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasMultiplePassengers) ...[
                const SizedBox(height: 4.0),
                Text(
                  '$passengerCount pax',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
