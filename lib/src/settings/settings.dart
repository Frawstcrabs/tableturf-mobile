// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game_internals/card.dart';
import '../game_internals/deck.dart';
import '../game_internals/tile.dart';
import '../level_selection/levels.dart';
import '../level_selection/opponents.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class SettingsController {
  late final SharedPreferences _prefs;
  static const commitChanges = false;

  static final SettingsController _controller = SettingsController._internal();

  factory SettingsController() {
    return _controller;
  }

  SettingsController._internal() {}

  // Whether or not the sound is on at all. This overrides both music and sound.
  ValueNotifier<bool> _muted = ValueNotifier(false);
  ValueNotifier<bool> _soundsOn = ValueNotifier(false);
  ValueNotifier<bool> _musicOn = ValueNotifier(false);
  ValueNotifier<bool> _continuousAnimation = ValueNotifier(false);
  ValueNotifier<String> _playerName = ValueNotifier('Player');
  late List<ValueNotifier<TableturfDeck>> _decks;
  late int _nextDeckID;
  final Map<TableturfCardIdentifier, TableturfCardData> _tempCards = {};

  ValueListenable<bool> get muted => _muted;
  ValueListenable<bool> get soundsOn => _soundsOn;
  ValueListenable<bool> get musicOn => _musicOn;
  ValueListenable<bool> get continuousAnimation => _continuousAnimation;
  ValueListenable<String> get playerName => _playerName;
  List<ValueNotifier<TableturfDeck>> get decks => List.unmodifiable(_decks);

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence(SharedPreferences prefs) async {
    _prefs = prefs;
    _musicOn.value = _prefs.getBool('musicOn') ?? true;
    _soundsOn.value = _prefs.getBool('soundsOn') ?? true;
    _continuousAnimation.value = _prefs.getBool('continuousAnimation') ?? false;
    _muted.value = _prefs.getBool('muted') ?? kIsWeb;
    _playerName.value = _prefs.getString('playerName') ?? "Player";
    _nextDeckID = _prefs.getInt("tableturf-deck_nextID") ?? 1;
    final List<dynamic> deckIDs = jsonDecode(_prefs.getString("tableturf-deck_list") ?? "[0]");
    _decks = deckIDs.map((deckID) {
      final deckDefault = '''{
        "name": "Deck 1",
        "cardSleeve": "default",
        "deckID": 0,
        "cards": ${jsonEncode([
          for (final cardID in [5, 12, 21, 27, 33, 39, 44, 51, 54, 55, 91, 102, 136, 140, 158])
            cards[cardID].ident.toJson()
        ])}
      }''';
      print(deckDefault);
      final Map<String, dynamic> deck = jsonDecode(
        _prefs.getString("tableturf-deck_deck-${deckID}") ?? deckDefault
      );
      return ValueNotifier(TableturfDeck(
        deckID: deckID,
        cards: [
          for (final cardJson in deck["cards"])
            TableturfCardIdentifier.fromJson(cardJson)
        ],
        name: deck["name"],
        cardSleeve: deck["cardSleeve"],
      ));
    }).toList();
    /*
    _nextDeckID = opponents.length - 1;
    _decks = opponents.sublist(0, opponents.length - 1).map((opponent) {
      return ValueNotifier(opponent.deck);
    }).toList();
     */
  }

  Iterable<int> get items sync* {
    yield 1;
  }

  void setPlayerName(String name) {
    _playerName.value = name;
    if (commitChanges)
      _prefs.setString('playerName', name);
  }

  void toggleMusicOn() {
    _musicOn.value = !_musicOn.value;
    if (commitChanges)
      _prefs.setBool('musicOn', _musicOn.value);
  }

  void toggleMuted() {
    _muted.value = !_muted.value;
    if (commitChanges)
      _prefs.setBool('muted', _muted.value);
  }

  void toggleSoundsOn() {
    _soundsOn.value = !_soundsOn.value;
    if (commitChanges)
      _prefs.setBool('soundsOn', _soundsOn.value);
  }

  void toggleContinuousAnimation() {
    _continuousAnimation.value = !_continuousAnimation.value;
    if (commitChanges)
      _prefs.setBool('continuousAnimation', _continuousAnimation.value);
  }

  void swapDecks(int deck1, int deck2) {
    final deck1Index = _decks.indexWhere((deck) => deck.value.deckID == deck1);
    final deck2Index = _decks.indexWhere((deck) => deck.value.deckID == deck2);
    final temp = decks[deck1Index].value;
    decks[deck1Index].value = decks[deck2Index].value;
    decks[deck2Index].value = temp;
    _writeDeckIndexes();
  }

  Future<void> _writeNextDeckID() async {
    if (commitChanges) {
      await _prefs.setInt("tableturf-deck_nextID", _nextDeckID);
    }
  }

  Future<void> _writeDeck(TableturfDeck deck) async {
    if (commitChanges) {
      await _prefs.setString(
        "tableturf-deck_deck-${deck.deckID}",
        jsonEncode(deck.toJson()),
      );
    }
  }

  Future<void> _writeDeckIndexes() async {
    if (commitChanges) {
      await _prefs.setString(
        "tableturf-deck_list",
        jsonEncode([for (final deck in _decks) deck.value.deckID]),
      );
    }
  }

  void updateDeck({
    required int deckID,
    List<TableturfCardIdentifier>? cards,
    String? name,
    String? cardSleeve,
  }) {
    final oldDeckIndex = _decks.indexWhere((deck) => deck.value.deckID == deckID);
    final oldDeck = _decks[oldDeckIndex].value;
    final newDeck = TableturfDeck(
      deckID: deckID,
      cards: cards ?? oldDeck.cards,
      name: name ?? oldDeck.name,
      cardSleeve: cardSleeve ?? oldDeck.cardSleeve,
    );
    _decks[oldDeckIndex].value = newDeck;
    _writeDeck(newDeck);
  }

  TableturfDeck createDeck({
    required List<TableturfCardIdentifier> cards,
    required String name,
    required String cardSleeve,
  }) {
    final deck = TableturfDeck(
      deckID: _nextDeckID,
      cards: cards,
      name: name,
      cardSleeve: cardSleeve,
    );
    _decks.add(ValueNotifier(deck));
    _nextDeckID += 1;
    () async {
      await _writeNextDeckID();
      await _writeDeck(deck);
      await _writeDeckIndexes();
    }();
    return deck;
  }

  void registerTempCard(TableturfCardData card) {
    _tempCards[card.ident] = card;
  }

  void removeTempCard(TableturfCardIdentifier ident) {
    _tempCards.remove(ident);
  }

  TableturfCardData identToCard(TableturfCardIdentifier ident) {
    switch (ident.type) {
      case TableturfCardType.official:
        return cards[ident.num - 1];
      case TableturfCardType.custom:
        throw Exception("custom ident passed");
      case TableturfCardType.randomiser:
        return _tempCards[ident]!;
    }
  }

  TileGrid getMap(String stage) {
    if (maps.containsKey(stage)) {
      return maps[stage]!.copy();
    }
    throw Exception("unknown map name");
  }
}
