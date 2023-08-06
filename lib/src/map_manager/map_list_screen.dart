import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';
import 'package:tableturf_mobile/src/settings/settings.dart';

import '../game_internals/map.dart';
import '../components/card_widget.dart';
import '../components/map_thumbnail.dart';
import '../player_progress/player_progress.dart';
import '../style/constants.dart';
import 'map_editor_screen.dart';

enum MapPopupActions {
  delete,
  duplicate,
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
    final mediaQuery = MediaQuery.of(context);
    final playerProgress = PlayerProgress();
    final mapList = playerProgress.maps;
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
                        final bool? changesMade = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) {
                            return MapEditorScreen(map: null);
                          })
                        );
                        if (changesMade == true) {
                          setState(() {});
                        }
                        _lockButtons = false;
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Palette.mapThumbnailBorder,
                            width: 3.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                          color: Palette.mapThumbnailBackground,
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
                      final bool? changesMade = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) {
                          return MapEditorScreen(map: mapList[index].value);
                        })
                      );
                      if (changesMade == true) {
                        setState(() {});
                      }
                      _lockButtons = false;
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ListenableBuilder(
                          listenable: mapList[index],
                          builder: (context, __) {
                            final mapNotifier = mapList[index];
                            final textStyle = DefaultTextStyle.of(context).style;
                            const duration = Duration(milliseconds: 200);
                            return Draggable<ValueNotifier<TableturfMap>>(
                              data: mapNotifier,
                              maxSimultaneousDrags: 1,
                              feedback: DefaultTextStyle(
                                style: textStyle,
                                child: Opacity(
                                    opacity: 0.8,
                                    child: ConstrainedBox(
                                      constraints: constraints,
                                      child: MapThumbnail(map: mapNotifier.value),
                                    )
                                ),
                              ),
                              childWhenDragging: Container(),
                              child: DragTarget<ValueNotifier<TableturfMap>>(
                                builder: (_, accepted, rejected) {
                                  return AnimatedOpacity(
                                    opacity: accepted.length > 0 ? 0.8 : 1.0,
                                    duration: duration,
                                    //curve: curve,
                                    child: AnimatedScale(
                                      scale: accepted.length > 0 ? 0.8 : 1.0,
                                      duration: duration,
                                      curve: Curves.ease,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          MapThumbnail(map: mapNotifier.value),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: PopupMenuButton<MapPopupActions>(
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Colors.white,
                                              ),
                                              onSelected: (val) {
                                                switch (val) {
                                                  case MapPopupActions.delete:
                                                    playerProgress.deleteMap(mapNotifier.value.mapID);
                                                    setState(() {});
                                                    break;
                                                  case MapPopupActions.duplicate:
                                                    playerProgress.duplicateMap(mapNotifier.value.mapID);
                                                    setState(() {});
                                                    break;
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  child: Text("Delete"),
                                                  value: MapPopupActions.delete,
                                                ),
                                                PopupMenuItem(
                                                  child: Text("Duplicate"),
                                                  value: MapPopupActions.duplicate,
                                                ),
                                              ],
                                            )
                                          )
                                        ],
                                      )
                                    ),
                                  );
                                },
                                onWillAccept: (newMap) => !identical(mapNotifier, newMap),
                                onAccept: (newMap) {
                                  playerProgress.swapMaps(mapNotifier.value.mapID, newMap.value.mapID);
                                },
                              )
                            );
                          }
                        );
                      }
                    ),
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
          backgroundColor: Palette.backgroundMapList,
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


