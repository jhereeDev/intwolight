// ignore_for_file: avoid_print
import 'package:in_two_lights/forms.dart';
import 'package:in_two_lights/geom.dart';
import 'package:in_two_lights/level.dart';
import 'package:in_two_lights/mesh.dart';

void show(String label, List<Mesh2> sh) {
  const n = 46;
  final m = Mask(n);
  for (final s in sh) {
    fillTriangles(m, s.v, s.t);
  }
  print('--- $label ---');
  for (var j = n - 1; j >= 0; j -= 1) {
    final row = StringBuffer();
    for (var i = 0; i < n; i++) {
      row.write(m.bits[j * n + i] != 0 ? '##' : '..');
    }
    print(row);
  }
}

void main() {
  for (final lv in silhouetteLevels) {
    final w = worldMeshes(lv, lv.solution);
    show('${lv.name}  WALL B (the designed one)', shadowMeshes(w, toWallB));
    show('${lv.name}  WALL A (the abstract constraint)', shadowMeshes(w, toWallA));
    final rt = LevelRuntime(lv);
    print('${lv.name}: at solution '
        '${rt.score(lv.solution).a.toStringAsFixed(2)}/'
        '${rt.score(lv.solution).b.toStringAsFixed(2)}  '
        'at origin solved=${rt.score(const Pose(0, 0, 0)).solved}\n');
  }
}
