import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const CombatTimerApp());
}

class CombatTimerApp extends StatelessWidget {
  const CombatTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combat Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TimerScreen(),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  double _workDuration = 0.5; // minuti
  double _restDuration = 0.5; // minuti
  int _cycles = 3;
  int _currentCycle = 1;
  int _secondsLeft = 0;
  bool _isWorking = true;
  bool _isRunning = false;
  bool _finished = false; // Stato programma completato

  Timer? _timer;
  final Random _random = Random();
  final AudioPlayer _beepPlayer = AudioPlayer();
  final AudioPlayer _gongPlayer = AudioPlayer();

  String _frequency = 'Medio'; // Lento, Medio, Veloce

  @override
  void dispose() {
    _timer?.cancel();
    _beepPlayer.dispose();
    _gongPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = (_workDuration * 60).toInt();
    _currentCycle = 1;
    _isWorking = true;
    _isRunning = true;
    _finished = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          if (_isWorking) {
            _isWorking = false;
            _secondsLeft = (_restDuration * 60).toInt();
            _gongPlayer.play(AssetSource('sounds/gong.wav'));
          } else {
            if (_currentCycle < _cycles) {
              _currentCycle++;
              _isWorking = true;
              _secondsLeft = (_workDuration * 60).toInt();
              _gongPlayer.play(AssetSource('sounds/gong.wav'));
            } else {
              _stopTimer();
              _gongPlayer.play(AssetSource('sounds/gong.wav'));
              _finished = true;
            }
          }
        }
      });
    });

    _startRandomSoundLoop();
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    setState(() {});
  }

  void _resetTimer() {
    _stopTimer();
    _secondsLeft = (_workDuration * 60).toInt();
    _currentCycle = 1;
    _isWorking = true;
    _finished = false;
    setState(() {});
  }

  void _startRandomSoundLoop() {
    Future.delayed(_randomDelay(), () async {
      if (!_isRunning || !_isWorking) return;
      if (_random.nextBool()) {
        await _beepPlayer.play(AssetSource('sounds/beep.wav'));
      } else {
        await _gongPlayer.play(AssetSource('sounds/gong.wav'));
      }
      if (_isWorking) _startRandomSoundLoop();
    });
  }

  Duration _randomDelay() {
    double minDelay, maxDelay;
    switch (_frequency) {
      case 'Lento':
        minDelay = 0.8;
        maxDelay = 2.0;
        break;
      case 'Veloce':
        minDelay = 0.2;
        maxDelay = 0.7;
        break;
      default:
        minDelay = 0.4;
        maxDelay = 1.2;
    }
    final seconds = minDelay + _random.nextDouble() * (maxDelay - minDelay);
    return Duration(milliseconds: (seconds * 1000).toInt());
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Future<void> _openSettings() async {
    // Apre il pannello impostazioni con valori correnti e aspetta i nuovi valori
    final result = await showModalBottomSheet<_SettingsData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SettingsSheet(
          workDuration: _workDuration,
          restDuration: _restDuration,
          cycles: _cycles,
          frequency: _frequency,
        );
      },
    );

    // Se result non nullo applica solo alla chiusura impostazioni
    if (result != null) {
      setState(() {
        _workDuration = result.workDuration;
        _restDuration = result.restDuration;
        _cycles = result.cycles;
        _frequency = result.frequency;
        // Se timer fermo aggiorna tempo visualizzato
        if (!_isRunning) {
          _secondsLeft = (_workDuration * 60).toInt();
          _currentCycle = 1;
          _isWorking = true;
          _finished = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
        _isWorking ? (_workDuration * 60).toInt() : (_restDuration * 60).toInt();
    final progress = total > 0 ? (1 - (_secondsLeft / total)) : 0.0;

    Color backgroundColor;
    Color progressColor;
    Color progressBackgroundColor;

    if (_finished) {
      backgroundColor = Colors.grey[800]!;
      progressColor = Colors.grey[400]!;
      progressBackgroundColor = Colors.grey[700]!;
    } else if (_isWorking) {
      backgroundColor = Colors.green[700]!;
      progressColor = Colors.green[300]!;
      progressBackgroundColor = Colors.green[900]!.withOpacity(0.3);
    } else {
      backgroundColor = Colors.blue[700]!;
      progressColor = Colors.blue[300]!;
      progressBackgroundColor = Colors.blue[900]!.withOpacity(0.3);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final fullWidth = constraints.maxWidth;
              final barWidth = (progress.clamp(0.0, 1.0)) * fullWidth;
              return Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: barWidth,
                  height: constraints.maxHeight,
                  color: progressColor.withOpacity(0.22),
                ),
              );
            }),
            Column(
              children: [
                // Barra superiore con icona impostazioni (aggiungi qui eventuali altre icone)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Qui puoi aggiungere altre icone o info a sinistra, o lasciarlo vuoto
                      SizedBox(width: 48),
                      // Icona impostazioni a destra
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 32),
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _isWorking ? "ROUND" : (_finished ? "FINITO" : "REST"),
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                // Timer responsive e mai a capo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatTime(_secondsLeft),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 140,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Ciclo $_currentCycle / $_cycles",
                  style: const TextStyle(fontSize: 28, color: Colors.white70),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    color: progressColor,
                    backgroundColor: progressBackgroundColor,
                    minHeight: 6,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 50,
                      color: Colors.white,
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow),
                    ),
                    IconButton(
                      iconSize: 50,
                      color: Colors.white,
                      onPressed: _stopTimer,
                      icon: const Icon(Icons.stop),
                    ),
                    IconButton(
                      iconSize: 50,
                      color: Colors.white,
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      iconSize: 50,
                      color: Colors.white,
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsData {
  final double workDuration;
  final double restDuration;
  final int cycles;
  final String frequency;

  _SettingsData({
    required this.workDuration,
    required this.restDuration,
    required this.cycles,
    required this.frequency,
  });
}

class SettingsSheet extends StatefulWidget {
  final double workDuration;
  final double restDuration;
  final int cycles;
  final String frequency;

  const SettingsSheet({
    Key? key,
    required this.workDuration,
    required this.restDuration,
    required this.cycles,
    required this.frequency,
  }) : super(key: key);

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late double _workDuration;
  late double _restDuration;
  late int _cycles;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    _workDuration = widget.workDuration;
    _restDuration = widget.restDuration;
    _cycles = widget.cycles;
    _frequency = widget.frequency;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Impostazioni',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Durata round (min): ${_workDuration.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Slider(
              value: _workDuration,
              min: 0.5,
              max: 10,
              divisions: ((10 - 0.5) * 2).toInt(),
              label: _workDuration.toStringAsFixed(1),
              onChanged: (v) {
                setState(() => _workDuration = v);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Durata pausa (min): ${_restDuration.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Slider(
              value: _restDuration,
              min: 0.1,
              max: 5,
              divisions: ((5 - 0.1) * 10).toInt(),
              label: _restDuration.toStringAsFixed(1),
              onChanged: (v) {
                setState(() => _restDuration = v);
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cicli: $_cycles',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Slider(
              value: _cycles.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: _cycles.toString(),
              onChanged: (v) {
                setState(() => _cycles = v.toInt());
              },
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Frequenza eventi',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Lento', 'Medio', 'Veloce'].map((f) {
                final selected = _frequency == f;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected ? Colors.teal : Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _frequency = f;
                        });
                      },
                      child: Text(f, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _SettingsData(
                    workDuration: _workDuration,
                    restDuration: _restDuration,
                    cycles: _cycles,
                    frequency: _frequency,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Chiudi'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
