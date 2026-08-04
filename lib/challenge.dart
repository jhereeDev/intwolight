import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'level.dart';
import 'scene.dart';

/// A challenge card: the room and the two target shadows, and **no sculpture**.
///
/// The naive "share my result" is a screenshot of the solved room — which hands
/// the recipient the answer. A daily is the same puzzle for everyone, so
/// spoiling it is the one thing a challenge must not do. This renders the
/// question instead: here are the two shadows, find the pose.
///
/// Drawn straight into a [ui.PictureRecorder] rather than captured from a
/// widget, because the thing being shared is not on screen anywhere — the
/// player is looking at a solved room, and the card has to show an empty one.
Future<Uint8List?> renderChallengeCard(
  Level level, {
  Size size = const Size(430, 860),
  double pixelRatio = 3,
}) async {
  final rt = LevelRuntime(level);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.scale(pixelRatio);
  canvas.drawRect(
      Offset.zero & size, Paint()..color = const Color(0xFF08080A));

  CornerScenePainter(
    // Empty: the room, lit, with both targets and nothing casting into them.
    world: const [],
    castA: const [],
    castB: const [],
    targetsA: unionOutline2D(rt.targetShadowsA()),
    targetsB: unionOutline2D(rt.targetShadowsB()),
    hitA: false,
    hitB: false,
    glow: 0,
    motes: _motes,
  ).paint(canvas, size);

  final image = await recorder.endRecording().toImage(
        (size.width * pixelRatio).round(),
        (size.height * pixelRatio).round(),
      );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png?.buffer.asUint8List();
}

final List<Offset> _motes = [
  for (var i = 0; i < 26; i++)
    Offset(_rand(i * 2) * 0.9 + 0.05, _rand(i * 2 + 1) * 0.7 + 0.12),
];

double _rand(int i) {
  final x = math.sin(i * 12.9898 + 78.233) * 43758.5453;
  return x - x.floorToDouble();
}
