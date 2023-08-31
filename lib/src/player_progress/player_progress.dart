// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableturf_mobile/src/game_internals/card.dart';
import 'package:tableturf_mobile/src/game_internals/opponentAI.dart';
import 'package:tableturf_mobile/src/game_internals/tile.dart';

import '../game_internals/deck.dart';
import '../game_internals/map.dart';

const rankRequirements = [
   100,  200,  300,  400,  500,  600,  700,  800,  900, 1000,
  1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000,
  2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000,
  3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000,
  4100, 4200, 4300, 4400, 4500, 4600, 4700, 4800, 4900,
];
final maxRankAmount = rankRequirements.reduce((a, b) => a + b);

int calculateXpToRank(int xp) {
  int ret = 1;
  for (final amount in rankRequirements) {
    if (amount > xp) {
      break;
    }
    ret += 1;
    xp -= amount;
  }
  return ret;
}

const starterDeck = TableturfDeck(
  deckID: 0,
  name: "Starter Deck",
  cardSleeve: "default",
  cards: [
    TableturfCardIdentifier(6, TableturfCardType.official),
    TableturfCardIdentifier(13, TableturfCardType.official),
    TableturfCardIdentifier(22, TableturfCardType.official),
    TableturfCardIdentifier(28, TableturfCardType.official),
    TableturfCardIdentifier(34, TableturfCardType.official),
    TableturfCardIdentifier(40, TableturfCardType.official),
    TableturfCardIdentifier(45, TableturfCardType.official),
    TableturfCardIdentifier(52, TableturfCardType.official),
    TableturfCardIdentifier(55, TableturfCardType.official),
    TableturfCardIdentifier(56, TableturfCardType.official),
    TableturfCardIdentifier(92, TableturfCardType.official),
    TableturfCardIdentifier(103, TableturfCardType.official),
    TableturfCardIdentifier(137, TableturfCardType.official),
    TableturfCardIdentifier(141, TableturfCardType.official),
    TableturfCardIdentifier(159, TableturfCardType.official),
  ]
);

/// Encapsulates the player's progress.
class PlayerProgress {
  late final SharedPreferences _prefs;
  static const DIFFICULTY_UNLOCK_THRESHOLD = 3;
  static const _commitChanges = kReleaseMode;

  static final PlayerProgress _controller = PlayerProgress._internal();

  factory PlayerProgress() {
    return _controller;
  }

  PlayerProgress._internal() {}

  final Map<TableturfCardIdentifier, TableturfCardData> _tempCards = {};

  late Map<String, Map<AILevel, int>> _winCounts;

  late int _xp;
  late final ValueNotifier<int> cash;
  late Map<TableturfCardIdentifier, int> _unlockedCards;
  late Set<String> _unlockedCardSleeves;
  late Set<int> _unlockedOpponents;
  late int _nextDeckID;
  late List<ValueNotifier<TableturfDeck>> _decks;
  late int _nextMapID;
  late List<ValueNotifier<TableturfMap>> _maps;

  Map<TableturfCardIdentifier, int> get unlockedCards => _unlockedCards;
  Set<int> get unlockedOpponents => _unlockedOpponents;
  Set<String> get unlockedCardSleeves => _unlockedCardSleeves;
  List<ValueNotifier<TableturfDeck>> get decks => List.unmodifiable(_decks);
  List<ValueNotifier<TableturfMap>> get maps => List.unmodifiable(_maps);

  int get xp => _xp;
  set xp(int value) {
    _xp = value;
    if (_commitChanges) {
      _prefs.setInt("tableturf-xp", value);
    }
  }

  int get rank => calculateXpToRank(_xp);

  /// Asynchronously loads values from the injected persistence store.
  Future<void> loadStateFromPersistence(SharedPreferences prefs) async {
    _prefs = prefs;
    final Map<String, dynamic> winCountJson = jsonDecode(
      _prefs.getString("tableturf-wins") ?? "{}"
    );
    _winCounts = Map.fromEntries(winCountJson.entries.map((entry) {
      final opponentID = entry.key;
      final winCounts = entry.value as Map<String, dynamic>;

      return MapEntry(
        opponentID,
        Map.fromEntries(winCounts.entries
          .where((winEntry) {
            final key = int.parse(winEntry.key);
            return key >= 0 && key < AILevel.values.length;
          })
          .map((winEntry) {
            return MapEntry(
              AILevel.values[int.parse(winEntry.key)],
              winEntry.value as int
            );
          })
        )
      );
    }));
    _xp = _prefs.getInt("tableturf-xp") ?? 0;
    cash = ValueNotifier(
      _prefs.getInt("tableturf-cash") ?? 0,
    );
    cash.addListener(() {
      if (_commitChanges) {
        _prefs.setInt("tableturf-cash", cash.value);
      }
    });

    final List<dynamic> unlockedOpponentsJson = jsonDecode(
      _prefs.getString("tableturf-unlocked_opponents") ?? "[-1]"
    );
    _unlockedOpponents = unlockedOpponentsJson.map((i) => i as int).toSet();

    final List<dynamic> unlockedCardSleevesJson = jsonDecode(
      _prefs.getString("tableturf-unlocked_card_sleeves") ?? '["default"]'
    );
    _unlockedCardSleeves = unlockedCardSleevesJson.map((s) => s as String).toSet();

    dynamic unlockedCardsJson = jsonDecode(
      _prefs.getString("tableturf-unlocked_cards") ?? jsonEncode({
        for (final card in starterDeck.cards)
          jsonEncode(card!.toJson()): 1
      })
    );
    if (unlockedCardsJson is List<dynamic>) {
      unlockedCardsJson = Map.fromEntries(unlockedCardsJson.map(
        (ident) => MapEntry(jsonEncode(ident), 1),
      ));
    }
    _unlockedCards = (unlockedCardsJson as Map<String, dynamic>).map((key, value) {
      return MapEntry(
        TableturfCardIdentifier.fromJson(
          jsonDecode(key) as Map<String, dynamic>,
        ),
        value as int,
      );
    });


    _nextDeckID = _prefs.getInt("tableturf-deck_nextID") ?? 1;
    final deckIDsJson = _prefs.getString("tableturf-deck_list");
    if (deckIDsJson == null) {
      _decks = [ValueNotifier(starterDeck)];
    } else {
      final List<dynamic> deckIDs = jsonDecode(deckIDsJson);
      _decks = deckIDs.map((deckID) {
        final deckJson = _prefs.getString("tableturf-deck_deck-${deckID}");
        if (deckJson == null) {
          return null;
        }
        final Map<String, dynamic> deck = jsonDecode(deckJson);
        return ValueNotifier(TableturfDeck(
          deckID: deckID,
          cards: [
            for (final cardJson in deck["cards"])
              TableturfCardIdentifier.fromJson(cardJson)
          ],
          name: deck["name"],
          cardSleeve: deck["cardSleeve"],
        ));
      }).whereNotNull().toList();
    }

    _nextMapID = _prefs.getInt("tableturf-map_nextID") ?? 1;
    final List<dynamic> mapIDs = jsonDecode(_prefs.getString("tableturf-map_list") ?? "[]");
    _maps = mapIDs.map((mapID) {
      final Map<String, dynamic> map = jsonDecode(_prefs.getString("tableturf-map_map-${mapID}")!);
      return ValueNotifier(TableturfMap.fromJson(map));
    }).toList();
  }

  Future<void> _writeWinCounts() async {
    if (_commitChanges) {
      final encodedJson = jsonEncode({
        for (final entry in _winCounts.entries)
          entry.key: {
            for (final winEntry in entry.value.entries)
              winEntry.key.index.toString(): winEntry.value,
          },
      });
      await _prefs.setString("tableturf-wins", encodedJson);
    }
  }

  Map<AILevel, int> getWins(String key) {
    if (!_winCounts.containsKey(key)) {
      _winCounts[key] = {
        for (final level in AILevel.values)
          level: 0,
      };
    }
    return _winCounts[key]!;
  }

  int incrementWins(String key, AILevel difficulty) {
    final difficultyMap = _winCounts[key]!;
    if (!difficultyMap.containsKey(difficulty)) {
      difficultyMap[difficulty] = 1;
    } else {
      difficultyMap[difficulty] = difficultyMap[difficulty]! + 1;
    }
    _writeWinCounts();
    return difficultyMap[difficulty]!;
  }

  Future<void> _writeUnlockedOpponents() async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-unlocked_opponents",
        jsonEncode(_unlockedOpponents.toList()),
      );
    }
  }

  void unlockOpponent(int opponentID) {
    _unlockedOpponents.add(opponentID);
    _writeUnlockedOpponents();
  }

  Future<void> _writeUnlockedCardSleeves() async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-unlocked_card_sleeves",
        jsonEncode(_unlockedCardSleeves.toList()),
      );
    }
  }

  void unlockCardSleeve(String cardSleeve) {
    _unlockedCardSleeves.add(cardSleeve);
    _writeUnlockedCardSleeves();
  }

  Future<void> _writeUnlockedCards() async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-unlocked_cards",
        jsonEncode(_unlockedCards.map((key, value) {
          return MapEntry(
            jsonEncode(key.toJson()),
            value,
          );
        }),
      ));
    }
  }

  void unlockCard(TableturfCardIdentifier ident) {
    _unlockedCards.putIfAbsent(ident, () => 1);
    _writeUnlockedCards();
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
    if (_commitChanges) {
      await _prefs.setInt("tableturf-deck_nextID", _nextDeckID);
    }
  }

  Future<void> _writeDeck(TableturfDeck deck) async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-deck_deck-${deck.deckID}",
        jsonEncode(deck.toJson()),
      );
    }
  }

  Future<void> _writeDeckIndexes() async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-deck_list",
        jsonEncode([for (final deck in _decks) deck.value.deckID]),
      );
    }
  }

  Future<void> _writeDecks() async {
    await Future.wait([
      _writeNextDeckID(),
      _writeDeckIndexes(),
      for (final deck in _decks)
        _writeDeck(deck.value),
    ]);
  }

  Future<void> _deleteDeck(int deckID) async {
    if (_commitChanges) {
      await _prefs.remove("tableturf-deck_deck-$deckID");
    }
  }

  void updateDeck({
    required int deckID,
    String? name,
    List<TableturfCardIdentifier?>? cards,
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
    required String name,
    required List<TableturfCardIdentifier?> cards,
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

  void duplicateDeck(int deckID) {
    final oldDeckIndex = _decks.indexWhere((deck) => deck.value.deckID == deckID);
    final oldDeck = _decks[oldDeckIndex].value;
    final deck = TableturfDeck(
      deckID: _nextDeckID,
      cards: oldDeck.cards,
      name: oldDeck.name,
      cardSleeve: oldDeck.cardSleeve,
    );
    _decks.insert(oldDeckIndex + 1, ValueNotifier(deck));
    _nextDeckID += 1;
        () async {
      await _writeNextDeckID();
      await _writeDeck(deck);
      await _writeDeckIndexes();
    }();
  }

  void setDeckSleeve(int deckID, String newSleeve) {
    updateDeck(deckID: deckID, cardSleeve: newSleeve);
  }

  void setDeckName(int deckID, String newName) {
    updateDeck(deckID: deckID, name: newName);
  }

  void deleteDeck(int deckID) {
    _decks.removeWhere((deck) => deck.value.deckID == deckID);
        () async {
      await _deleteDeck(deckID);
      await _writeDeckIndexes();
    }();
  }

  Future<void> _writeNextMapID() async {
    if (_commitChanges) {
      await _prefs.setInt("tableturf-map_nextID", _nextMapID);
    }
  }

  Future<void> _writeMap(TableturfMap map) async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-map_map-${map.mapID}",
        jsonEncode(map.toJson()),
      );
    }
  }

  Future<void> _writeMapIndexes() async {
    if (_commitChanges) {
      await _prefs.setString(
        "tableturf-map_list",
        jsonEncode([for (final map in _maps) map.value.mapID]),
      );
    }
  }

  Future<void> _deleteMap(int mapID) async {
    if (_commitChanges) {
      await _prefs.remove("tableturf-map_map-$mapID");
    }
  }

  void swapMaps(int map1, int map2) {
    final map1Index = _maps.indexWhere((map) => map.value.mapID == map1);
    final map2Index = _maps.indexWhere((map) => map.value.mapID == map2);
    final temp = maps[map1Index].value;
    maps[map1Index].value = maps[map2Index].value;
    maps[map2Index].value = temp;
    _writeMapIndexes();
  }

  void updateMap({
    required int mapID,
    String? name,
    TileGrid? board,
  }) {
    final oldMapIndex = _maps.indexWhere((map) => map.value.mapID == mapID);
    final oldMap = _maps[oldMapIndex].value;
    final newMap = TableturfMap(
      mapID: mapID,
      name: name ?? oldMap.name,
      board: board?.copy() ?? oldMap.board,
    );
    _maps[oldMapIndex].value = newMap;
    _writeMap(newMap);
  }

  TableturfMap createMap({
    required String name,
    required TileGrid board,
  }) {
    final map = TableturfMap(
      mapID: _nextMapID,
      name: name,
      board: board.copy(),
    );
    _maps.add(ValueNotifier(map));
    _nextMapID += 1;
        () async {
      await _writeNextMapID();
      await _writeMap(map);
      await _writeMapIndexes();
    }();
    return map;
  }

  void duplicateMap(int mapID) {
    final oldMapIndex = _maps.indexWhere((map) => map.value.mapID == mapID);
    final oldMap = _maps[oldMapIndex].value;
    final map = TableturfMap(
        mapID: _nextMapID,
        name: oldMap.name,
        board: oldMap.board.copy()
    );
    _maps.insert(oldMapIndex + 1, ValueNotifier(map));
    _nextMapID += 1;
        () async {
      await _writeNextMapID();
      await _writeMap(map);
      await _writeMapIndexes();
    }();
  }

  void deleteMap(int mapID) {
    _maps.removeWhere((map) => map.value.mapID == mapID);
        () async {
      await _deleteMap(mapID);
      await _writeMapIndexes();
    }();
  }

  TableturfMap getMap(int mapID) {
    return officialMaps.firstWhere(
            (m) => m.mapID == mapID,
        orElse: () => _maps.firstWhere(
              (m) => m.value.mapID == mapID,
        ).value
    );
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
        return officialCards[ident.num - 1];
      case TableturfCardType.custom:
        throw Exception("custom ident passed");
      case TableturfCardType.randomiser:
        return _tempCards[ident]!;
    }
  }

  Future<void> reset() async {
    for (final entry in _winCounts.entries) {
      for (final winEntry in entry.value.entries) {
        entry.value[winEntry.key] = 0;
      }
    }
    _unlockedOpponents = Set.from([-1]);
    _unlockedCards = {for (final card in starterDeck.cards) card!: 1};
    _unlockedCardSleeves = Set.from(["default"]);
    xp = 0;
    cash.value = 0;
    _decks = [ValueNotifier(starterDeck)];
    _nextDeckID = 1;
    await Future.wait([
      for (final deck in _decks)
        _deleteDeck(deck.value.deckID),
    ]);
    await Future.wait([
      _writeWinCounts(),
      _writeUnlockedOpponents(),
      _writeUnlockedCards(),
      _writeUnlockedCardSleeves(),
      _writeDecks(),
    ]);
  }
}
