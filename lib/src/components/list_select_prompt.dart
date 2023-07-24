import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';

import '../card_manager/card_popup_transition_painter.dart';
import 'card_widget.dart';

class _ListSelectOverlayController<T> {
  late _ListSelectOverlayState<T> state;
  Completer<T?> completer = Completer();
}

typedef ListSelectBuilder<T> = Widget Function(BuildContext, void Function(T?));

class _ListSelectOverlay<T> extends StatefulWidget {
  final String title;
  final ListSelectBuilder<T> builder;
  final Animation<double> popupAnimation;
  final _ListSelectOverlayController<T> controller;
  final Listenable popupExit;
  const _ListSelectOverlay({
    super.key,
    required this.title,
    required this.builder,
    required this.popupAnimation,
    required this.controller,
    required this.popupExit,
  });

  @override
  State<_ListSelectOverlay<T>> createState() => _ListSelectOverlayState();
}

class _ListSelectOverlayState<T> extends State<_ListSelectOverlay<T>> {
  late final Animation<double> _popupScale, _popupOpacity;
  late final Animation<Decoration> _popupBackgroundDecoration;
  late final ScrollController scrollController;
  final SnapshotController snapshotController = SnapshotController(
    allowSnapshotting: true
  );

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();

    _popupScale = CurvedAnimation(
      parent: Tween(begin: 0.0, end: 1.0).animate(widget.popupAnimation),
      curve: Curves.easeOutBack,
      reverseCurve: Curves.linear,
    ).drive(Tween(begin: 0.6, end: 1.0));
    _popupOpacity = Tween(
        begin: 0.0,
        end: 1.0
    )
    //.chain(CurveTween(curve: Curves.easeOut))
        .animate(widget.popupAnimation);
    _popupBackgroundDecoration = DecorationTween(
      begin: BoxDecoration(color: Colors.transparent),
      end: BoxDecoration(color: const Color.fromRGBO(0, 0, 0, 0.7)),
    ).animate(widget.popupAnimation);

    widget.popupExit.addListener(onPopupExit);
    widget.popupAnimation.addStatusListener(_checkAnimStatus);
    widget.controller.state = this;
  }

  @override
  void dispose() {
    widget.popupAnimation.removeStatusListener(_checkAnimStatus);
    scrollController.dispose();
    snapshotController.dispose();
    widget.popupExit.removeListener(onPopupExit);
    super.dispose();
  }

  void _checkAnimStatus(AnimationStatus status) {
    snapshotController.allowSnapshotting = status != AnimationStatus.completed;
  }

  Future<void> onPopupExit([T? retValue]) async {
    print("completing popup with $retValue");
    Navigator.of(context).pop(retValue);
  }

  @override
  Widget build(BuildContext context) {
    const borderWidth = 1.0;
    const divider = const Divider(
      color: Colors.black,
      height: 0.5,
      thickness: 0.5,
    );
    return DefaultTextStyle(
      style: TextStyle(
          fontFamily: "Splatfont2",
          color: Colors.black,
          fontSize: 16,
          letterSpacing: 0.6,
          shadows: [
            Shadow(
              color: const Color.fromRGBO(256, 256, 256, 0.4),
              offset: Offset(1, 1),
            )
          ]
      ),
      child: AnimatedBuilder(
          animation: widget.popupAnimation,
          child: Center(
            child: FractionallySizedBox(
              heightFactor: 0.8,
              widthFactor: 0.8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(width: borderWidth),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[800],
                ),
                child: Padding(
                  padding: EdgeInsets.all(borderWidth),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Text(
                            widget.title,
                            style: TextStyle(color: Colors.white),
                          )
                        ),
                      ),
                      divider,
                      Expanded(
                        flex: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.grey[600]
                          ),
                          child: RepaintBoundary(
                            child: widget.builder(context, onPopupExit),
                          ),
                        ),
                      ),
                      divider,
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 4.0,
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: SelectionButton(
                                child: Text("Cancel"),
                                designRatio: 0.5,
                                onPressEnd: () async {
                                  onPopupExit();
                                  return Future<void>.delayed(const Duration(milliseconds: 100));
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                  ),
                ),
              ),
            ),
          ),
          builder: (_, child) {
          return Stack(
            children: [
              GestureDetector(
                onTap: onPopupExit,
                child: DecoratedBoxTransition(
                  decoration: _popupBackgroundDecoration,
                  child: SizedBox.expand(),
                )
              ),
              SnapshotWidget(
                controller: snapshotController,
                painter: CardPopupTransitionPainter(
                  popupScale: _popupScale,
                  popupOpacity: _popupOpacity,
                ),
                child: child,
              ),
            ]
          );
        }
      ),
    );
  }
}


Future<T?> showListSelectPrompt<T>(BuildContext context, {
  required String title,
  required ListSelectBuilder<T> builder,
}) async {
  final controller = _ListSelectOverlayController();
  final popupExitNotifier = ChangeNotifier();
  final T? ret = await Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    opaque: false,
    pageBuilder: (ctx, animation, __) {
      return WillPopScope(
        onWillPop: () async {
          popupExitNotifier.notifyListeners();
          return false;
        },
        child: _ListSelectOverlay(
          title: title,
          builder: builder,
          popupAnimation: animation,
          controller: controller,
          popupExit: popupExitNotifier,
        ),
      );
    }
  ));
  popupExitNotifier.dispose();
  return ret;
}