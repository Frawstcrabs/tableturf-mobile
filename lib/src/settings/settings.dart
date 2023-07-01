// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game_internals/card.dart';
import '../game_internals/deck.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to an injected persistence store.
class SettingsController {
  final SharedPreferences _prefs;

  /// Creates a new instance of [SettingsController] backed by [persistence].
  SettingsController({required SharedPreferences prefs})
      : _prefs = prefs;

  // Whether or not the sound is on at all. This overrides both music and sound.
  ValueNotifier<bool> _muted = ValueNotifier(false);
  ValueNotifier<bool> _soundsOn = ValueNotifier(false);
  ValueNotifier<bool> _musicOn = ValueNotifier(false);
  ValueNotifier<String> _playerName = ValueNotifier('Player');
  late List<TableturfDeck> _decks;
  late int _nextDeckID;

  ValueListenable<bool> get muted => _muted;
  ValueListenable<bool> get soundsOn => _soundsOn;
  ValueListenable<bool> get musicOn => _musicOn;
  ValueListenable<String> get playerName => _playerName;
  List<TableturfDeck> get decks => _decks;

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence() async {
    _musicOn.value = _prefs.getBool('musicOn') ?? true;
    _soundsOn.value = _prefs.getBool('soundsOn') ?? true;
    _muted.value = _prefs.getBool('muted') ?? kIsWeb;
    _playerName.value = _prefs.getString('playerName') ?? "Player";
    _nextDeckID = _prefs.getInt("tableturf-deck_nextID")!;
    final deckIDs = jsonDecode(_prefs.getString("tableturf-deck_list")!) as List<dynamic>;
    _decks = deckIDs.map((deckID) {
      final deck = jsonDecode(_prefs.getString("tableturf-deck_deck-${deckID}")!);
      return TableturfDeck(
        deckID: deckID,
        cards: [
          for (final cardJson in deck["cards"]!)
            TableturfCardData.fromJson(cardJson)
        ],
        name: deck["name"]!,
        cardSleeve: deck["cardSleeve"]!,
      );
    }).toList();
  }

  void setPlayerName(String name) {
    _playerName.value = name;
    _prefs.setString('playerName', name);
  }

  void toggleMusicOn() {
    _musicOn.value = !_musicOn.value;
    _prefs.setBool('musicOn', _musicOn.value);
  }

  void toggleMuted() {
    _muted.value = !_muted.value;
    _prefs.setBool('muted', _muted.value);
  }

  void toggleSoundsOn() {
    _soundsOn.value = !_soundsOn.value;
    _prefs.setBool('soundsOn', _soundsOn.value);
  }

  void swapDecks(int deck1, int deck2) {
    final deck1Index = _decks.indexWhere((deck) => deck.deckID == deck1);
    final deck2Index = _decks.indexWhere((deck) => deck.deckID == deck2);
    final temp = decks[deck1Index];
    decks[deck1Index] = decks[deck2Index];
    decks[deck2Index] = temp;
    _writeDeckIndexes();
  }

  Future<void> _writeDeck(TableturfDeck deck) async {
    await _prefs.setString(
      "tableturf-deck_deck-${deck.deckID}",
      jsonEncode(deck.toJson()),
    );
  }

  Future<void> _writeDeckIndexes() async {
    await _prefs.setString(
      "tableturf-deck_list",
      jsonEncode([for (final deck in _decks) deck.deckID]),
    );
  }

  void updateDeck({
    required int deckID,
    List<TableturfCardData>? cards,
    String? name,
    String? cardSleeve,
  }) {
    final oldDeckIndex = _decks.indexWhere((deck) => deck.deckID == deckID);
    final oldDeck = _decks[oldDeckIndex];
    final newDeck = TableturfDeck(
      deckID: deckID,
      cards: cards ?? oldDeck.cards,
      name: name ?? oldDeck.name,
      cardSleeve: cardSleeve ?? oldDeck.cardSleeve,
    );
    _decks[oldDeckIndex] = newDeck;
    _writeDeck(newDeck);
  }

  TableturfDeck createDeck({
    required List<TableturfCardData> cards,
    required String name,
    required String cardSleeve,
  }) {
    final deck = TableturfDeck(
      deckID: _nextDeckID,
      cards: cards,
      name: name,
      cardSleeve: cardSleeve,
    );
    _decks.add(deck);
    _nextDeckID += 1;
    () async {
      await _prefs.setInt("tableturf-deck_nextID", _nextDeckID);
      await _writeDeck(deck);
      await _writeDeckIndexes();
    }();
    return deck;
  }
}
