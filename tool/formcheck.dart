// ignore_for_file: avoid_print

import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/level.dart';

void main() {
  for (final lv in formLevels) {
    final rt = LevelRuntime(lv);
    final s = lv.solution;
    final row = <String>[];
    for (final d in [0.0, 0.35, 0.7, 1.4, 2.2, 3.14]) {
      final sc = rt.score(Pose(s.yaw + d, s.pitch, s.hinge));
      row.add('${d.toStringAsFixed(2)}:${sc.a.toStringAsFixed(2)}/'
          '${sc.b.toStringAsFixed(2)}${sc.solved ? "*" : ""}');
    }
    print('${lv.name.padRight(8)} ${row.join("  ")}');
  }
}
