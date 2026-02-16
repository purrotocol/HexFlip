import 'dart:math';
import 'package:flutter/painting.dart';
import '../models/hex_cell.dart';

/// Returns the neighbor coordinate of [origin] in direction [sideIndex] (0..5).
AxialCoord neighborAt(AxialCoord origin, int sideIndex) {
  assert(sideIndex >= 0 && sideIndex < 6, 'sideIndex must be 0..5');
  return origin + AxialCoord.directions[sideIndex];
}

/// Returns the side index on the opposite face: (sideIndex + 3) % 6.
int oppositeSide(int sideIndex) => (sideIndex + 3) % 6;

/// Returns all 6 neighbors of [origin] with the side index from origin to each.
List<({AxialCoord coord, int sideIndex})> neighborsOf(AxialCoord origin) {
  return List.generate(6, (i) => (coord: neighborAt(origin, i), sideIndex: i));
}

/// Returns the visual rotation in radians for a given side index.
/// Used as the single source of truth for UI rendering.
double sideRotationRadians(int sideIndex) => sideIndex * pi / 3;

/// Converts axial coordinates to pixel center using flat-top hex layout.
///
/// Formula (flat-top):
///   x = size * (3/2 * q)
///   y = size * (sqrt(3)/2 * q + sqrt(3) * r)
Offset hexToPixel(AxialCoord coord, double size) {
  final x = size * (3.0 / 2.0 * coord.q);
  final y = size * (sqrt(3.0) / 2.0 * coord.q + sqrt(3.0) * coord.r);
  return Offset(x, y);
}

/// Converts a pixel offset back to the nearest axial coordinate.
/// Inverse of [hexToPixel] using cube coordinate rounding.
AxialCoord pixelToHex(Offset pixel, double size) {
  // Invert flat-top formula:
  //   q = (2/3) * x / size
  //   r = (-1/3 * x + sqrt(3)/3 * y) / size
  final q = (2.0 / 3.0) * pixel.dx / size;
  final r = (-1.0 / 3.0 * pixel.dx + sqrt(3.0) / 3.0 * pixel.dy) / size;

  // Convert to cube coordinates for rounding: s = -q - r
  final s = -q - r;

  // Round each cube coordinate to the nearest integer
  var rq = q.round();
  var rr = r.round();
  var rs = s.round();

  // Fix the largest rounding error to maintain q + r + s == 0
  final qDiff = (rq - q).abs();
  final rDiff = (rr - r).abs();
  final sDiff = (rs - s).abs();

  if (qDiff > rDiff && qDiff > sDiff) {
    rq = -rr - rs;
  } else if (rDiff > sDiff) {
    rr = -rq - rs;
  }
  // rs is discarded; axial only uses q and r

  return AxialCoord(rq, rr);
}
