import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'all_constants.dart';
import 'reusable_card.dart';
import 'package:application_learning_english/models/word.dart';

class FlashCard extends StatefulWidget {
  final List<Word> words;
  final bool isShuffle;
  final bool isEnglish;
  final bool autoPronounce;
  final bool starCard;

  const FlashCard({
    Key? key,
    required this.words,
    required this.isShuffle,
    required this.autoPronounce,
    required this.isEnglish,
    required this.starCard,
  }) : super(key: key);

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> {
  late List<Map<String, String>> wordPairs;
  int _currentIndexNumber = 0;
  double _initial = 0.1;
  bool isFlipped = false;
  bool autoFlippedEnable = false;
  double _startX = 0;
  double _endX = 0;
  Timer? flipTimer;
  Timer? changeCardTimer;
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    getDataWord();
    if (widget.isShuffle) {
      wordPairs.shuffle();
    }
    if (widget.autoPronounce) {
      pronounceCurrentWord();
    }
  }

  void getDataWord() {
    if (widget.starCard) {
      List<Map<String, String>> getStarredWordPairs(List<Word> words) {
        return words
            .where((word) => word.isStarred) // Lọc các từ có isStarred = true
            .map((word) {
          return {'english': word.english, 'vietnamese': word.vietnamese};
        }).toList();
      }

      wordPairs = getStarredWordPairs(widget.words);
    } else {
      wordPairs = widget.words.map((word) {
        return {'english': word.english, 'vietnamese': word.vietnamese};
      }).toList();
    }
  }

  @override
  void dispose() {
    flipTimer?.cancel();
    changeCardTimer?.cancel();
    super.dispose();
  }

  void startAutoFlip() {
    flipTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      cardKey.currentState?.toggleCard();
      setState(() {
        isFlipped = !isFlipped;
      });

      if (isFlipped) {
        changeCardTimer = Timer(Duration(seconds: 5), () {
          cardKey.currentState?.toggleCard();
          setState(() {
            isFlipped = false;
            showNextCard();
          });
        });
      } else {
        showNextCard();
      }
    });
  }

  void stopAutoFlip() {
    flipTimer?.cancel();
    changeCardTimer?.cancel();
  }

  void toggleAutoFlip() {
    setState(() {
      autoFlippedEnable = !autoFlippedEnable;
      if (autoFlippedEnable) {
        startAutoFlip();
      } else {
        stopAutoFlip();
      }
    });
  }

  void pronounceCurrentWord() {
    String textToSpeak = wordPairs[_currentIndexNumber][isFlipped
        ? (widget.isEnglish ? 'vietnamese' : 'english')
        : (widget.isEnglish ? 'english' : 'vietnamese')]!;
    flutterTts.speak(textToSpeak);
  }

  @override
  Widget build(BuildContext context) {
    String value = "${_currentIndexNumber + 1} of ${wordPairs.length}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Flashcards App", style: TextStyle(fontSize: 30)),
        backgroundColor: mainColor,
        toolbarHeight: 80,
        elevation: 5,
        shadowColor: mainColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          Row(
            children: [
              Text("Auto Flip", style: TextStyle(fontSize: 16)),
              Switch(
                value: autoFlippedEnable,
                onChanged: (value) {
                  toggleAutoFlip();
                },
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Question $value Completed", style: otherTextStyle),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation(mainColor),
                minHeight: 5,
                value: _initial,
              ),
            ),
            SizedBox(height: 25),
            GestureDetector(
              onHorizontalDragStart: (details) {
                _startX = details.globalPosition.dx;
                stopAutoFlip();
              },
              onHorizontalDragUpdate: (details) {
                _endX = details.globalPosition.dx;
              },
              onHorizontalDragEnd: (details) {
                final double delta = _endX - _startX;
                if (delta > 0) {
                  if (_currentIndexNumber > 0) {
                    showPreviousCard();
                  }
                } else {
                  if (_currentIndexNumber < wordPairs.length - 1) {
                    showNextCard();
                  }
                }
              },
              child: SizedBox(
                width: 300,
                height: 300,
                child: FlipCard(
                  key: cardKey,
                  direction: FlipDirection.HORIZONTAL,
                  flipOnTouch: false,
                  front: GestureDetector(
                    onTap: () {
                      cardKey.currentState?.toggleCard();
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                      if (widget.autoPronounce) {
                        pronounceCurrentWord();
                      }
                    },
                    child: Stack(children: [
                      ReusableCard(
                        text: wordPairs[_currentIndexNumber]
                        [widget.isEnglish ? 'english' : 'vietnamese']!,
                      ),
                      Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: Icon(Icons.volume_up),
                            onPressed: () {
                              flutterTts.speak(wordPairs[_currentIndexNumber][
                              widget.isEnglish
                                  ? 'english'
                                  : 'vietnamese']!);
                            },
                          ))
                    ]),
                  ),
                  back: GestureDetector(
                    onTap: () {
                      cardKey.currentState?.toggleCard();
                      setState(() {
                        isFlipped = !isFlipped;
                      });
                      if (widget.autoPronounce) {
                        pronounceCurrentWord();
                      }
                    },
                    child: Stack(children: [
                      ReusableCard(
                        text: wordPairs[_currentIndexNumber]
                        [widget.isEnglish ? 'vietnamese' : 'english']!,
                      ),
                      Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            icon: Icon(Icons.volume_up),
                            onPressed: () {
                              flutterTts.speak(wordPairs[_currentIndexNumber][
                              widget.isEnglish
                                  ? 'vietnamese'
                                  : 'english']!);
                            },
                          ))
                    ]),
                  ),
                ),
              ),
            ),
            Text("Tap to view", style: otherTextStyle),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: showPreviousCard,
                  child: Icon(Icons.arrow_back),
                ),
                ElevatedButton(
                  onPressed: showNextCard,
                  child: Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void updateToNext() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber + 1) % wordPairs.length;
      _initial = (_currentIndexNumber + 1) / wordPairs.length;
    });
    if (widget.autoPronounce) {
      pronounceCurrentWord();
    }
  }

  void updateToPrev() {
    setState(() {
      _currentIndexNumber = (_currentIndexNumber - 1 >= 0)
          ? _currentIndexNumber - 1
          : wordPairs.length - 1;
      _initial = (_currentIndexNumber + 1) / wordPairs.length;
    });
    if (widget.autoPronounce) {
      pronounceCurrentWord();
    }
  }

  void showNextCard() {
    setState(() {
      if (isFlipped) {
        cardKey.currentState?.toggleCard();
        isFlipped = false;
      }
      _currentIndexNumber = (_currentIndexNumber + 1) % wordPairs.length;
      _initial = (_currentIndexNumber + 1) / wordPairs.length;
    });
    if (widget.autoPronounce) {
      pronounceCurrentWord();
    }
  }

  void showPreviousCard() {
    setState(() {
      if (isFlipped) {
        cardKey.currentState?.toggleCard();
        isFlipped = false;
      }
      _currentIndexNumber = (_currentIndexNumber - 1 >= 0)
          ? _currentIndexNumber - 1
          : wordPairs.length - 1;
      _initial = (_currentIndexNumber + 1) / wordPairs.length;
    });
    if (widget.autoPronounce) {
      pronounceCurrentWord();
    }
  }
}
