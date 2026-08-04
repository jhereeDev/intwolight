import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'endless.dart';
import 'level.dart';
import 'main.dart';
import 'progress.dart';

const _amber = Color(0xFFE0A82E);
const _bg = Color(0xFF08080A);

/// Generates a room off the UI isolate.
///
/// ⚠️ Not optional. Measured: a 0-joint room costs ~37ms to generate and a
/// hinged one ~1s on a desktop, and a phone is several times slower. Doing that
/// on the main isolate would freeze the app for seconds between rooms.
Future<Level> _generate(int room) => compute(endlessLevelFor, room);

/// ENDLESS — the campaign ends, this does not.
///
/// One room at a time, generated on the device and numbered from 1. The room
/// number IS the progress key, so depth survives reinstalls and a shared room
/// number means the same puzzle on someone else's phone.
class EndlessScreen extends StatefulWidget {
  const EndlessScreen({super.key, required this.progress});

  /// The endless ledger — keyed by room number, never by level index.
  final Progress progress;

  @override
  State<EndlessScreen> createState() => _EndlessScreenState();
}

class _EndlessScreenState extends State<EndlessScreen> {
  late int _room = widget.progress.deepestRoom + 1;
  Level? _level;
  Object? _error;

  /// Room [_room] + 1, already being generated while the player works on the
  /// current one. By the time they press NEXT it is usually just sitting here,
  /// which is what makes an expensive generator feel instant.
  Future<Level>? _ahead;

  @override
  void initState() {
    super.initState();
    _load(_room);
  }

  Future<void> _load(int room) async {
    setState(() {
      _level = null;
      _error = null;
    });
    try {
      // Use the prefetch if it is for this room, otherwise generate now.
      final lv = await (_ahead ?? _generate(room));
      if (!mounted) return;
      setState(() {
        _room = room;
        _level = lv;
      });
      // Start the next one immediately, not when NEXT is pressed.
      _ahead = _generate(room + 1);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _Message(
        text: 'This room would not settle.',
        action: 'TRY THE NEXT ONE',
        onAction: () {
          _ahead = null;
          _load(_room + 1);
        },
      );
    }
    if (_level == null) {
      return _Message(text: 'ROOM $_room', action: null, onAction: null);
    }
    return PlayScreen(
      // Keyed by room so each one gets a fresh PlayScreen rather than
      // inheriting the previous room's pose and glow.
      key: ValueKey(_room),
      index: 0,
      progress: widget.progress,
      levels: [_level!],
      // The ledger is keyed by DEPTH, not by position in this one-item list.
      progressKey: (_) => _room,
      shareTitle: 'Endless · Room $_room',
      // Endless has no answer key to protect — every player gets the same
      // room, so sharing the puzzle rather than the solution is right here
      // for the same reason it is on the daily.
      challenge: true,
      onBeyond: () {
        _ahead = _ahead; // keep the prefetch; _load will consume it
        _load(_room + 1);
      },
    );
  }
}

/// Loading and error both look like a room with the lights off, rather than a
/// spinner on a black screen — the wait is part of the same place.
class _Message extends StatelessWidget {
  const _Message(
      {required this.text, required this.action, required this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 22),
                  color: Colors.white38,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text,
                        style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 6,
                            color: Colors.white38)),
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.4, color: _amber),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 26),
                      TextButton(
                        onPressed: onAction,
                        child: Text(action!,
                            style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 3,
                                color: _amber)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
