import 'nakshatra_calculator.dart';
import 'workbook_moon_boundary.dart';

/// UTC start/end instants for the Moon's current Nakshatra and Pada.
///
/// The boundary solver intentionally mirrors the Master Workbook's
/// established two-step lunar boundary calculation. The Workbook does not
/// use a converged bisection; it uses the Moon's longitude velocity over
/// +/-12h and two successive linear corrections.
class MoonNakshatraWindow {
  final DateTime startUtc;
  final DateTime endUtc;
  final DateTime padaStartUtc;
  final DateTime padaEndUtc;

  const MoonNakshatraWindow({
    required this.startUtc,
    required this.endUtc,
    required this.padaStartUtc,
    required this.padaEndUtc,
  });

  static const double _nakshatraSize = 360.0 / 27.0;
  static const double _padaSize = _nakshatraSize / 4.0;

  static MoonNakshatraWindow forUtc(DateTime utc) {
    assert(utc.isUtc, 'Pass a true UTC DateTime.');

    final current = NakshatraCalculator.computeCurrent(utc);
    final currentIndex = current.nakshatraIndex1to27;
    final currentPada = current.pada;

    final nakshatraStartDeg = (currentIndex - 1) * _nakshatraSize;
    final nakshatraEndDeg = currentIndex * _nakshatraSize;
    final padaStartDeg =
        nakshatraStartDeg + (currentPada - 1) * _padaSize;
    final padaEndDeg = nakshatraStartDeg + currentPada * _padaSize;

    final startUtc = WorkbookMoonBoundary.workbookBoundary(
      utc: utc,
      targetSiderealLongitude: nakshatraStartDeg,
    );
    final endUtc = WorkbookMoonBoundary.workbookBoundary(
      utc: utc,
      targetSiderealLongitude: nakshatraEndDeg,
    );
    final padaStartUtc = currentPada == 1
        ? startUtc
        : WorkbookMoonBoundary.workbookBoundary(
            utc: utc,
            targetSiderealLongitude: padaStartDeg,
          );
    final padaEndUtc = currentPada == 4
        ? endUtc
        : WorkbookMoonBoundary.workbookBoundary(
            utc: utc,
            targetSiderealLongitude: padaEndDeg,
          );

    return MoonNakshatraWindow(
      startUtc: startUtc,
      endUtc: endUtc,
      padaStartUtc: padaStartUtc,
      padaEndUtc: padaEndUtc,
    );
  }
}
