import 'package:hive/hive.dart';
import '../models/fare_formula.dart';

class FareCacheService {
  static const String _boxName = 'fareFormulas';

  /// Opens the Hive box for FareFormula
  Future<Box<FareFormula>> openBox() async {
    return await Hive.openBox<FareFormula>(_boxName);
  }

  /// Seeds the box with default data if it's empty
  Future<void> seedDefaults() async {
    final box = await openBox();
    if (box.isEmpty) {
      final defaultFormulas = [
        FareFormula(
          subType: 'Traditional Jeepney',
          baseFare: 14.00,
          perKmRate: 1.75,
          provincialMultiplier: 1.20,
          notes: 'Standard formula',
        ),
        FareFormula(
          subType: 'White Taxi',
          baseFare: 45.00,
          perKmRate: 13.50,
          notes: 'Regular Taxi',
        ),
        FareFormula(
          subType: 'Yellow Taxi',
          baseFare: 75.00,
          perKmRate: 20.00,
          notes: 'Airport Taxi',
        ),
      ];
      await box.addAll(defaultFormulas);
    }
  }

  /// Retrieves all FareFormula objects from the box
  Future<List<FareFormula>> getAllFormulas() async {
    final box = await openBox();
    return box.values.toList();
  }

  /// Saves a list of FareFormula objects to the box, replacing existing ones
  Future<void> saveFormulas(List<FareFormula> formulas) async {
    final box = await openBox();
    await box.clear();
    await box.addAll(formulas);
  }
}