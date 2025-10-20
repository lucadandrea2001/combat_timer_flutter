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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Impostazioni",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildSlider(
                  label: "Durata round (min): ${_workDuration.toStringAsFixed(1)}",
                  value: _workDuration,
                  min: 0.5,
                  max: 5,
                  onChanged: (v) => setModalState(() => _workDuration = v),
                ),
                _buildSlider(
                  label: "Durata pausa (min): ${_restDuration.toStringAsFixed(1)}",
                  value: _restDuration,
                  min: 0.5,
                  max: 5,
                  onChanged: (v) => setModalState(() => _restDuration = v),
                ),
                _buildSlider(
                  label: "Cicli: $_cycles",
                  value: _cycles.toDouble(),
                  min: 1,
                  max: 20,
                  onChanged: (v) => setModalState(() => _cycles = v.toInt()),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _frequency,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  items: ['Lento', 'Medio', 'Veloce']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setModalState(() => _frequency = v!),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("Chiudi"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(), // divisioni da 0.5 in 0.5 minuti
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _isWorking ? (_workDuration * 60).toInt() : (_restDuration * 60).toInt();
    final progress = 1 - (_secondsLeft / total);

    return Scaffold(
      backgroundColor: _isWorking ? Colors.green[700] : Colors.blue[700],
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 32),
                onPressed: _openSettings,
              ),
            ),
            const Spacer(),
            Text(
              _isWorking ? "ROUND" : "REST",
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _formatTime(_secondsLeft),
              style: const TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Ciclo $_currentCycle / $_cycles",
              style: const TextStyle(fontSize: 28, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            LinearProgressIndicator(
              value: progress,
              color: Colors.white,
              backgroundColor: Colors.white24,
              minHeight: 25,
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
      ),
    );
  }
}
