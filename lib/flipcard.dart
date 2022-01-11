import 'dart:convert';
import 'dart:math';
import 'package:FlipCard/cardbox.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:FlipCard/models/card_back.dart';
import 'package:FlipCard/models/card_front.dart';
import 'package:FlipCard/res/category_creation.dart';
import 'package:FlipCard/res/colors.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamePage extends StatefulWidget {
  final String cardBoxId;
  const GamePage({Key? key, required this.cardBoxId}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

Map cardBox = {};

String cardBoxId = '';

List shuffled = [];
double _rotationFactor = 0;

void refresh = (){};

class _GamePageState extends State<GamePage> {
  @override
  void initState() {
    super.initState();
    setSharedPrefs();
    int i = 1;
    print('initState Run $i times \n Shuffled: $shuffled');
    i++;
    createShuffledList();
    
  }

  @override
  Widget build(BuildContext context) {
    /* final arguments = ModalRoute.of(context)!.settings.arguments as Map;
    categoryID = arguments['categoryid'];
    cardsetID = arguments['cardsetid']; */

    cardBoxId = widget.cardBoxId;

    return Scaffold(backgroundColor: Colors.transparent, body: _GameScreen());
  }

  createShuffledList() async {
    final _prefs = SharedPreferences.getInstance();
    prefs = await _prefs;
    await setSharedPrefs();
    refreshCardBoxScreen;
    cardBox = json.decode(prefs.getString(cardBoxId).toString());

    shuffled = [];
    print('Create shuffled list');
    //Add nonexisting ones one by one
    for (Map card in cardBox['cards']) {
      if (card['status'] != 'done') {
        shuffled.add(card);
      }
    }
    shuffled.shuffle();
  }
}

class _GameScreen extends StatefulWidget {
  const _GameScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<_GameScreen> createState() => _GameScreenState();
}

var _flipAnimationController;
var _flipAnimation;
AnimationStatus _animationStatus = AnimationStatus.dismissed;

class _GameScreenState extends State<_GameScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    _flipAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _flipAnimation =
        Tween<double>(begin: 0, end: 1).animate(_flipAnimationController)
        ..addListener(() {
          setState(() {
            _flipAnimation;
            _flipAnimationController;
            refresh;
            });
        })
        ..addStatusListener((status) {setState(() {
          _animationStatus = status;
        });});

    WidgetsBinding.instance!.addPostFrameCallback(getWidgetInfo);
  }

  final GlobalKey _widgetKey = GlobalKey();

  double height = 0;
  double width = 0;

  bool isRun = false;
  int scrollIndex = 0;

  void getWidgetInfo(_) {
    final RenderBox renderBox =
        _widgetKey.currentContext!.findRenderObject() as RenderBox;
    final widgetSize = renderBox.size;
    height = renderBox.size.height;
    width = renderBox.size.width;

    isRun = true; //If the build is complete, activate onScroll for CarouselSlider
    print("SIZE of widget game screen: $widgetSize");
  }

  @override
  Widget build(BuildContext context) {
    
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundLight, backgroundDark])),
      child: SafeArea(
          child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
            padding: EdgeInsets.all(0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder(
                      stream: updateCard(),
                      builder: (context, async) {
                        refresh = () {setState(() {});};
                        return CarouselSlider.builder(
                            key: _widgetKey,
                            itemCount: shuffled.length,
                            options: CarouselOptions(
                              enableInfiniteScroll: false,
                              aspectRatio: .9,
                              enlargeCenterPage: true,
                              autoPlay: false,
                              onPageChanged: (index, reason) {
                                if (isRun) {
                                  if (_flipAnimation.value > 0.5) {
                                    _flipAnimationController.reverse();
                                  }
                                }
                                scrollIndex = index;
                              },
                            ),
                            itemBuilder: (context, index, realIndex) {
                              return StreamBuilder(
                                  stream: updateAnimation(scrollIndex),
                                  builder: (context, async) {
                                    return GestureDetector(
                                      onVerticalDragUpdate: (d) async {
                                        if (_flipAnimation.value < 0.5) {
                                          _flipAnimationController.forward();
                                        } else {
                                          _flipAnimationController.reverse();
                                        }
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Transform(
                                          transform: Matrix4.identity()
                                            ..setEntry(3, 2, 0.001)
                                            ..rotateX(pi * _flipAnimation.value),
                                          origin: Offset(width / 2, height / 2),
                                          child: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(20))),
                                            child: _flipAnimation.value > 0.5
                                                ? CardBackView(shuffled[index])
                                                : CardFrontView(
                                                    shuffled[index]),
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                            });
                      }),
                  Container(
                    padding: EdgeInsets.only(left: 40, right: 40),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    FlipCard();
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(top: 10, right: 3),
                                  height: 55,
                                  decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            spreadRadius: -10, blurRadius: 15)
                                      ],
                                      color: blueMediumLight,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  child: Center(
                                      child: Text(
                                    'Flip',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.white),
                                  )),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  Map item = shuffled[scrollIndex];
                                  await turnBack();
                                  setState(() {
                                    shuffled.removeAt(scrollIndex);
                                    shuffled.add(item);
                                    _flipAnimation;
                                  });
                                  print('RUN => Ask Later');
                                },
                                child: Container(
                                  margin: EdgeInsets.only(top: 10, right: 3),
                                  height: 55,
                                  decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            spreadRadius: -0.2, blurRadius: 5)
                                      ],
                                      color: backgroundDark,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  child: Center(
                                      child: Text(
                                    'Ask Later',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.white),
                                  )),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  await turnBack();
                                  markAsDone(scrollIndex);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(top: 10, left: 3),
                                  height: 55,
                                  decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            spreadRadius: -10, blurRadius: 25)
                                      ],
                                      color: backgroundLight,
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20))),
                                  child: Center(
                                      child: Text(
                                    'Done',
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.white),
                                  )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  /* Slider(
                      value: _rotationFactor,
                      onChanged: (e) {
                        setState(() {
                          _rotationFactor = e;
                        });
                      }), */
                ],
              ),
            )),
      )),
    );
  }

  formatDate(String date) {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate = DateFormat('MM/dd').format(dateTime);
    return formattedDate;
  }

  Future FlipCard() async {
    if (_flipAnimation.value < 0.5) {
      _flipAnimationController.forward();
    } else {
      _flipAnimationController.reverse();
    }
  }

  Stream updateAnimation(int index) async* {
    setState(() {
      //Create animation for every card
      _flipAnimation; //Update only the one shown in the middle
    });
  }

  Stream updateCard() async* {
    setState(() {
      //Notify that card updated
      shuffled;
    });
  }

  int returnCardIndex(e) {
    List cards = cardBox['cards'] as List;
    int index = 0;
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['status'] != 'done') {
        if (cards[i]['id'] == e['id']) {
          index = i;
        }
      }
    }
    return index;
  }

  void markAsDone(int index) async {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    prefs = await _prefs;
    cardBox = json.decode(prefs.getString(cardBoxId).toString());

    String cardId = shuffled[index]['id'];

    for (int i = 0; i < cardBox['cards'].length; i++) {
      Map card = cardBox['cards'][i];
      if (cardId == card['id']) {
        cardBox['cards'][i]['status'] = 'done';
      }
    }

    await prefs.setString(cardBoxId, json.encode(cardBox));
    await setSharedPrefs();
    
    setState(() {
      refreshCardBoxScreen;
      cardBoxes;
      shuffled.removeAt(index);
    });

    

  }

  returnCardIndexFromShuffled(int scrollIndex) {
    //Return index
    int index = 0;
    List tempMap = cardBox['cards'];
    for (int i = 0; i < tempMap.length; i++) {
      if (tempMap[i]['id'] == shuffled[scrollIndex]['id']) {
        index = i;
        break;
      }
    }
    return index;
  }

  turnBack() {
    if (_flipAnimation.value > 0.5) {
      _flipAnimationController.reverse();
    }
  }

  returnUndone() {
    //This will pick undone cards from $shuffled
    List tempList = [];
    for (Map e in shuffled) {
      if (e['status'] != 'done') {
        tempList.add(e);
      }
    }
    return tempList;
  }
}

class CardWidget extends StatefulWidget {
  final int index;
  const CardWidget(
    this.index, {
    Key? key,
  }) : super(key: key);

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  final GlobalKey cardWidgetKey = GlobalKey();

  double height = 0;
  double width = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback(getWidgetInfo);
  }

  void getWidgetInfo(_) {
    final RenderBox renderBoxRed =
        cardWidgetKey.currentContext?.findRenderObject() as RenderBox;
    final widgetSize = renderBoxRed.size;
    height = renderBoxRed.size.height;
    width = renderBoxRed.size.width;

    print("SIZE of widget game screen: $widgetSize");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardWidgetKey,
      alignment: Alignment.center,
      color: Colors.tealAccent,
      child: GestureDetector(
        onVerticalDragUpdate: (e) {
          if (_flipAnimation.value < 0.5) {
            _flipAnimationController.forward();
          } else {
            _flipAnimationController.reverse();
          }
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.yellow,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(pi * _flipAnimation.value),
            origin: Offset(width / 2, height / 2 + 36.2),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: _flipAnimation.value > 0.5
                  ? Container(
                      alignment: Alignment.center,
                      color: Colors.black,
                      child: CardBackView(shuffled[widget.index]))
                  : CardFrontView(shuffled[widget.index]),
            ),
          ),
        ),
      ),
    );
  }
}