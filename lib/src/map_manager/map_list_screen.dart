import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/game_internals/player.dart';
import 'package:tableturf_mobile/src/play_session/components/board_widget.dart';
import 'package:tableturf_mobile/src/play_session/components/card_selection.dart';
import 'package:tableturf_mobile/src/play_session/components/selection_button.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';

import '../game_internals/card.dart';
import '../game_internals/map.dart';
import '../play_session/components/card_widget.dart';
import '../style/palette.dart';
import 'map_editor_screen.dart';


class MapThumbnail extends StatelessWidget {
  final TableturfMap map;
  const MapThumbnail({
    super.key,
    required this.map,
  });

  @override
  Widget build(BuildContext context) {
    const palette = Palette();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: palette.mapThumbnailBorder,
          width: 3.0,
        ),
        borderRadius: BorderRadius.circular(15.0),
        color: palette.mapThumbnailBackground,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        widthFactor: 0.9,
        child: Center(
          child: CustomPaint(
            painter: BoardPainter(
              board: map.board,
            ),
            child: AspectRatio(
              aspectRatio: map.board[0].length / map.board.length,
            ),
            isComplex: true,
          )
        ),
      )
    );
  }
}


class MapListScreen extends StatefulWidget {
  const MapListScreen({Key? key}) : super(key: key);

  @override
  State<MapListScreen> createState() => _MapListScreenState();
}

class _MapListScreenState extends State<MapListScreen>
    with SingleTickerProviderStateMixin {
  bool _lockButtons = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final mediaQuery = MediaQuery.of(context);
    final settings = SettingsController();
    final mapList = settings.maps.map((m) => m.value).toList();
    final screen = Column(
        children: [
          Expanded(
              flex: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide())
                ),
                child: Center(
                    child: Text(
                        "Map List",
                        style: TextStyle(
                          fontFamily: "Splatfont1",
                        )
                    )
                ),
              )
          ),
          Expanded(
              flex: 9,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  crossAxisCount: mediaQuery.orientation == Orientation.portrait ? 3 : 7,
                  childAspectRatio: CardWidget.CARD_RATIO
                ),
                padding: EdgeInsets.all(10),
                itemCount: mapList.length + 1,
                itemBuilder: (context, index) {
                  if (index == mapList.length) {
                    return GestureDetector(
                      onTap: () async {
                        if (_lockButtons) return;
                        _lockButtons = true;
                        final bool changesMade = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) {
                            return MapEditorScreen(map: null);
                          })
                        );
                        if (changesMade) {
                          setState(() {});
                        }
                        _lockButtons = false;
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: palette.mapThumbnailBorder,
                            width: 3.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                          color: palette.mapThumbnailBackground,
                        ),
                        child: FractionallySizedBox(
                          heightFactor: 0.4,
                          widthFactor: 0.4,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Icon(
                                Icons.add_circle_outline,
                                color: const Color.fromRGBO(0, 0, 0, 0.4),
                                size: 72,
                              ),
                            )
                          ),
                        )
                      ),
                    );
                  } else if (index > mapList.length) {
                    return null;
                  }
                  return GestureDetector(
                    onTap: () async {
                      if (_lockButtons) return;
                      _lockButtons = true;
                      final bool changesMade = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) {
                          return MapEditorScreen(map: mapList[index]);
                        })
                      );
                      if (changesMade) {
                        setState(() {});
                      }
                      _lockButtons = false;
                    },
                    child: MapThumbnail(map: mapList[index]),
                  );
                },
              )
          ),
          Expanded(
              flex: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide())
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SelectionButton(
                            child: Text("Back"),
                            designRatio: 0.5,
                            onPressStart: () async {
                              if (_lockButtons) return false;
                              _lockButtons = true;
                              return true;
                            },
                            onPressEnd: () async {
                              Navigator.of(context).pop();
                              return Future<void>.delayed(const Duration(milliseconds: 100));
                            },
                          ),
                        ),
                      ),
                    ]
                ),
              )
          ),
        ]
    );
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
          backgroundColor: palette.backgroundMapList,
          body: DefaultTextStyle(
            style: TextStyle(
                fontFamily: "Splatfont2",
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 0.6,
                shadows: [
                  Shadow(
                    color: const Color.fromRGBO(256, 256, 256, 0.4),
                    offset: Offset(1, 1),
                  )
                ]
            ),
            child: Padding(
              padding: mediaQuery.padding,
              child: screen,
            ),
          )
      ),
    );
  }
}


