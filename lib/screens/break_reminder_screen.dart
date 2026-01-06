import 'dart:math';
import 'package:flutter/material.dart';

class BreakReminderScreen extends StatefulWidget {
  final Future<void> Function() onBreakComplete;

  const BreakReminderScreen({
    super.key,
    required this.onBreakComplete,
  });

  @override
  State<BreakReminderScreen> createState() => _BreakReminderScreenState();
}

class _BreakReminderScreenState extends State<BreakReminderScreen> {
  String _currentGame = 'color';
  int _score = 0;
  int _targetScore = 5;
  Color? _targetColor;
  List<Color> _colorOptions = [];
  int _correctIndex = 0;
  int _mathAnswer = 0;
  int _mathNum1 = 0;
  int _mathNum2 = 0;
  List<int> _mathOptions = [];
  int _correctMathIndex = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    final random = Random();
    final games = ['color', 'math', 'memory'];
    _currentGame = games[random.nextInt(games.length)];
    
    if (_currentGame == 'color') {
      _setupColorGame();
    } else if (_currentGame == 'math') {
      _setupMathGame();
    } else {
      _setupMemoryGame();
    }
  }

  void _setupColorGame() {
    final random = Random();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
    ];
    _targetColor = colors[random.nextInt(colors.length)];
    _colorOptions = List.generate(4, (index) {
      if (index == 0) return _targetColor!;
      return colors[random.nextInt(colors.length)];
    });
    _colorOptions.shuffle();
    _correctIndex = _colorOptions.indexOf(_targetColor!);
  }

  void _setupMathGame() {
    final random = Random();
    _mathNum1 = random.nextInt(10) + 1;
    _mathNum2 = random.nextInt(10) + 1;
    _mathAnswer = _mathNum1 + _mathNum2;
    
    _mathOptions = [_mathAnswer];
    while (_mathOptions.length < 4) {
      final wrongAnswer = random.nextInt(20) + 1;
      if (!_mathOptions.contains(wrongAnswer)) {
        _mathOptions.add(wrongAnswer);
      }
    }
    _mathOptions.shuffle();
    _correctMathIndex = _mathOptions.indexOf(_mathAnswer);
  }

  void _setupMemoryGame() {
    // Simple memory game - just increment score
    setState(() {
      _score = 0;
    });
  }

  void _handleColorTap(int index) {
    if (index == _correctIndex) {
      setState(() {
        _score++;
      });
      if (_score >= _targetScore) {
        _completeBreak();
      } else {
        _setupColorGame();
      }
    } else {
      // Wrong answer - reset
      setState(() {
        _score = 0;
      });
      _setupColorGame();
    }
  }

  void _handleMathTap(int index) {
    if (index == _correctMathIndex) {
      setState(() {
        _score++;
      });
      if (_score >= _targetScore) {
        _completeBreak();
      } else {
        _setupMathGame();
      }
    } else {
      setState(() {
        _score = 0;
      });
      _setupMathGame();
    }
  }

  void _handleMemoryTap() {
    setState(() {
      _score++;
    });
    if (_score >= _targetScore) {
      _completeBreak();
    }
  }

  Future<void> _completeBreak() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Great job! Break time complete! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      await widget.onBreakComplete();
    }
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    return 'Color';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Break Time!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Let\'s play a quick game!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Score
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score: $_score / $_targetScore',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Game content
                Expanded(
                  child: _buildGame(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame() {
    if (_currentGame == 'color') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Find the color:',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getColorName(_targetColor!),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _targetColor,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(4, (index) {
              return GestureDetector(
                onTap: () => _handleColorTap(index),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _colorOptions[index],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black,
                      width: 3,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    } else if (_currentGame == 'math') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Solve the math:',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$_mathNum1 + $_mathNum2 = ?',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(4, (index) {
              return GestureDetector(
                onTap: () => _handleMathTap(index),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${_mathOptions[index]}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tap the button!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _handleMemoryTap,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.deepOrange,
                  width: 5,
                ),
              ),
              child: const Icon(
                Icons.touch_app,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
  }
}

