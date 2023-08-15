import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableturf_mobile/src/components/selection_button.dart';

import 'popup_transition_painter.dart';

typedef ListSelectBuilder<T> = Widget Function(BuildContext, void Function(T?));

class ListSelectOverlay<T> extends StatefulWidget {
  final String title;
  final ListSelectBuilder<T> builder;
  final Animation<double> popupAnimation;
  final void Function(T? ret) onExit;
  const ListSelectOverlay({
    super.key,
    required this.title,
    required this.builder,
    required this.popupAnimation,
    required this.onExit,
  });

  @override
  State<ListSelectOverlay<T>> createState() => _ListSelectOverlayState();
}

class _ListSelectOverlayState<T> extends State<ListSelectOverlay<T>> {
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

    widget.popupAnimation.addStatusListener(_checkAnimStatus);
  }

  @override
  void dispose() {
    widget.popupAnimation.removeStatusListener(_checkAnimStatus);
    scrollController.dispose();
    snapshotController.dispose();
    super.dispose();
  }

  void _checkAnimStatus(AnimationStatus status) {
    snapshotController.allowSnapshotting = status != AnimationStatus.completed;
  }

  Future<void> onPopupExit([T? retValue]) async {
    widget.onExit(retValue);
  }

  @override
  Widget build(BuildContext context) {
    const borderWidth = 1.0;
    const divider = const Divider(
      color: Colors.black,
      height: 0.5,
      thickness: 0.5,
    );
    final popup = Center(
      child: FractionallySizedBox(
        heightFactor: 0.8,
        widthFactor: 0.8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(width: borderWidth),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[600],
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
                    ),
                  ),
                ),
                divider,
                Expanded(
                  flex: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                    ),
                    child: widget.builder(context, onPopupExit),
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
              ],
            ),
          ),
        ),
      ),
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
        ],
      ),
      child: WillPopScope(
        onWillPop: () async {
          onPopupExit();
          return false;
        },
        child: RepaintBoundary(
          child: Stack(
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
                painter: PopupTransitionPainter(
                  popupScale: _popupScale,
                  popupOpacity: _popupOpacity,
                ),
                child: popup,
              ),
            ]
          ),
        ),
      ),
    );
  }
}


Future<T?> showListSelectPrompt<T>(BuildContext context, {
  required String title,
  required ListSelectBuilder<T> builder,
}) async {
  return await Navigator.of(context).push(PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    opaque: false,
    pageBuilder: (ctx, animation, __) {
      return ListSelectOverlay<T>(
        title: title,
        builder: builder,
        popupAnimation: animation,
        onExit: (ret) {
          Navigator.of(context).pop(ret);
        }
      );
    }
  ));
}