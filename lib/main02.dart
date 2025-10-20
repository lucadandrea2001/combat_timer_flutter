import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(CombatTimerApp());
}

class CombatTimerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combat Timer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TimerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum SoundSpeed { lento, medio, veloce }

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _workDuration = 180;
  int _restDuration = 30;
  int _cycles = 3;
  int _secondsLeft = 180;
  int _currentCycle = 1;
  bool _isWorking = true;
  Timer? _timer;

  final AudioPlayer _beepPlayer = AudioPlayer();
  final AudioPlayer _gongPlayer = AudioPlayer();
  Random _random = Random();
  int _nextBeep = 0;
  int _nextGong = 0;

  SoundSpeed _soundSpeed = SoundSpeed.medio;

  @override
  void initState() {
    super.initState();
    _showSettingsDialog();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _beepPlayer.dispose();
    _gongPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _workDuration;
    _currentCycle = 1;
    _isWorking = true;
    _setNextSounds();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;

        if (_isWorking) {
          if (_nextBeep <= 0) {
            _beepPlayer.play(AssetSource('sounds/beep.wav'));
            _nextBeep = _randomInterval();
          } else {
            _nextBeep--;
          }

          if (_nextGong <= 0) {
            _gongPlayer.play(AssetSource('sounds/gong.wav'));
            _nextGong = _randomInterval();
          } else {
            _nextGong--;
          }
        }

        // Cambio fase
        if (_secondsLeft <= 0) {
          if (_isWorking) {
            _isWorking = false;
            _secondsLeft = _restDuration;
            _gongPlayer.play(AssetSource('sounds/gong.wav'));
          } else {
            if (_currentCycle < _cycles) {
              _currentCycle++;
              _isWorking = true;
              _secondsLeft = _workDuration;
              _setNextSounds();
              _gongPlayer.play(AssetSource('sounds/gong.wav'));
            } else {
              _timer?.cancel();
              _gongPlayer.play(AssetSource('sounds/gong.wav'));
            }
          }
        }
      });
    });
  }

  int _randomInterval() {
    switch (_soundSpeed) {
      case SoundSpeed.lento:
        return _random.nextInt(2) + 1; // 1-2 sec
      case SoundSpeed.medio:
        return _random.nextInt(2); // 0-1 sec
      case SoundSpeed.veloce:
        return 0; // intervallo minimo
    }
  }

  void _setNextSounds() {
    _nextBeep = _randomInterval();
    _nextGong = _randomInterval() + 1; // evitare simultaneità
  }

  void _stopTimer() => _timer?.cancel();

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isWorking = true;
      _currentCycle = 1;
      _secondsLeft = _workDuration;
      _setNextSounds();
    });
  }

  String get _timeDisplay {
    int minutes = _secondsLeft ~/ 60;
    int seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    int total = _isWorking ? _workDuration : _restDuration;
    return (total - _secondsLeft) / total;
  }

Future<void> _showSettingsDialog() async {
  final workController = TextEditingController(text: (_workDuration ~/ 60).toString());
  final restController = TextEditingController(text: _restDuration.toString());
  final cyclesController = TextEditingController(text: _cycles.toString());
  SoundSpeed tempSpeed = _soundSpeed; // variabile temporanea

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Imposta timer"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: workController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Durata round (minuti)"),
                  ),
                  TextField(
                    controller: restController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Durata riposo (secondi)"),
                  ),
                  TextField(
                    controller: cyclesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Numero cicli"),
                  ),
                  SizedBox(height: 10),
                  Text("Frequenza suoni"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<SoundSpeed>(
                        value: SoundSpeed.lento,
                        groupValue: tempSpeed,
                        onChanged: (value) {
                          setStateDialog(() => tempSpeed = value!);
                        },
                      ),
                      Text("Lento"),
                      Radio<SoundSpeed>(
                        value: SoundSpeed.medio,
                        groupValue: tempSpeed,
                        onChanged: (value) {
                          setStateDialog(() => tempSpeed = value!);
                        },
                      ),
                      Text("Medio"),
                      Radio<SoundSpeed>(
                        value: SoundSpeed.veloce,
                        groupValue: tempSpeed,
                        onChanged: (value) {
                          setStateDialog(() => tempSpeed = value!);
                        },
                      ),
                      Text("Veloce"),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _workDuration = int.tryParse(workController.text)! * 60;
                    _restDuration = int.tryParse(restController.text)!;
                    _cycles = int.tryParse(cyclesController.text)!;
                    _secondsLeft = _workDuration;
                    _soundSpeed = tempSpeed; // aggiorno la variabile principale
                    _setNextSounds();
                  });
                  Navigator.of(context).pop();
                },
                child: Text("Conferma"),
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isWorking ? Colors.green : Colors.cyan,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 20,
                backgroundColor: Colors.white24,
                color: _isWorking ? Colors.white : Colors.blueAccent,
              ),
            ),
            Text(
              _timeDisplay,
              style: TextStyle(
                fontSize: 160,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Ciclo $_currentCycle / $_cycles",
              style: TextStyle(fontSize: 28, color: Colors.white70),
            ),
            SizedBox(height: 50),
		Row(
 		 mainAxisAlignment: MainAxisAlignment.center,
  		children: [
  		  // Play
  		  ElevatedButton(
   		   onPressed: _startTimer,
   		   style: ElevatedButton.styleFrom(
    		    shape: CircleBorder(),
     		   padding: EdgeInsets.all(24),
     		   backgroundColor: Colors.white,
      		  foregroundColor: Colors.black,
   		   ),
   		   child: Icon(Icons.play_arrow, size: 36),
 		   ),
 		   SizedBox(width: 20),

  		  // Stop
  		  ElevatedButton(
   		   onPressed: _stopTimer,
    		  style: ElevatedButton.styleFrom(
    		    shape: CircleBorder(),
     		   padding: EdgeInsets.all(24),
      		  backgroundColor: Colors.white,
      		  foregroundColor: Colors.black,
    		  ),
   		   child: Icon(Icons.stop, size: 36),
  		  ),
  		  SizedBox(width: 20),
		
   		 // Aggiorna / Reset
  		  ElevatedButton(
    		  onPressed: _resetTimer,
     		 style: ElevatedButton.styleFrom(
      		  shape: CircleBorder(),
      		  padding: EdgeInsets.all(24),
      		  backgroundColor: Colors.white,
      		  foregroundColor: Colors.black,
     		 ),
    		  child: Icon(Icons.refresh, size: 36),
  		  ),
  		  SizedBox(width: 20),

   		 // Impostazioni
   		 ElevatedButton(
    		  onPressed: _showSettingsDialog,
     		 style: ElevatedButton.styleFrom(
      		  shape: CircleBorder(),
       		 padding: EdgeInsets.all(24),
     		   backgroundColor: Colors.white,
       		 foregroundColor: Colors.black,
     		 ),
     		 child: Icon(Icons.settings, size: 36),
   		 ),
 		 ],
		),

          ],
        ),
      ),
    );
  }
}
