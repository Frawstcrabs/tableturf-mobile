import 'package:tableturf_mobile/src/game_internals/card.dart';

import '../game_internals/deck.dart';

class TableturfOpponent {
  final String name;
  final String map;
  final TableturfDeck deck;

  const TableturfOpponent({
    required this.name,
    required this.map,
    required this.deck,
  });
}

const List<TableturfOpponent> opponents = [
  TableturfOpponent(
      name: "Baby Jelly",
      map: "main_street",
      deck: TableturfDeck(
        deckID: -1,
        name: "Baby Jelly",
        cardSleeve: "default",
        cards: [TableturfCardIdentifier(6, TableturfCardType.official), TableturfCardIdentifier(13, TableturfCardType.official), TableturfCardIdentifier(22, TableturfCardType.official), TableturfCardIdentifier(28, TableturfCardType.official), TableturfCardIdentifier(34, TableturfCardType.official), TableturfCardIdentifier(40, TableturfCardType.official), TableturfCardIdentifier(45, TableturfCardType.official), TableturfCardIdentifier(52, TableturfCardType.official), TableturfCardIdentifier(55, TableturfCardType.official), TableturfCardIdentifier(56, TableturfCardType.official), TableturfCardIdentifier(92, TableturfCardType.official), TableturfCardIdentifier(103, TableturfCardType.official), TableturfCardIdentifier(137, TableturfCardType.official), TableturfCardIdentifier(141, TableturfCardType.official), TableturfCardIdentifier(159, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Cool Jelly",
      map: "main_street",
      deck: TableturfDeck(
        deckID: -2,
        name: "Cool Jelly",
        cardSleeve: "default",
        cards: [TableturfCardIdentifier(3, TableturfCardType.official), TableturfCardIdentifier(5, TableturfCardType.official), TableturfCardIdentifier(8, TableturfCardType.official), TableturfCardIdentifier(27, TableturfCardType.official), TableturfCardIdentifier(37, TableturfCardType.official), TableturfCardIdentifier(49, TableturfCardType.official), TableturfCardIdentifier(57, TableturfCardType.official), TableturfCardIdentifier(107, TableturfCardType.official), TableturfCardIdentifier(114, TableturfCardType.official), TableturfCardIdentifier(117, TableturfCardType.official), TableturfCardIdentifier(120, TableturfCardType.official), TableturfCardIdentifier(123, TableturfCardType.official), TableturfCardIdentifier(130, TableturfCardType.official), TableturfCardIdentifier(142, TableturfCardType.official), TableturfCardIdentifier(156, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Aggro Jelly",
      map: "thunder_point",
      deck: TableturfDeck(
        deckID: -3,
        name: "Aggro Jelly",
        cardSleeve: "default",
        cards: [TableturfCardIdentifier(9, TableturfCardType.official), TableturfCardIdentifier(10, TableturfCardType.official), TableturfCardIdentifier(15, TableturfCardType.official), TableturfCardIdentifier(17, TableturfCardType.official), TableturfCardIdentifier(24, TableturfCardType.official), TableturfCardIdentifier(26, TableturfCardType.official), TableturfCardIdentifier(36, TableturfCardType.official), TableturfCardIdentifier(41, TableturfCardType.official), TableturfCardIdentifier(43, TableturfCardType.official), TableturfCardIdentifier(47, TableturfCardType.official), TableturfCardIdentifier(54, TableturfCardType.official), TableturfCardIdentifier(111, TableturfCardType.official), TableturfCardIdentifier(126, TableturfCardType.official), TableturfCardIdentifier(132, TableturfCardType.official), TableturfCardIdentifier(151, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Sheldon",
      map: "x_marks_the_garden",
      deck: TableturfDeck(
        deckID: -4,
        name: "Sheldon",
        cardSleeve: "sheldon",
        cards: [TableturfCardIdentifier(10, TableturfCardType.official), TableturfCardIdentifier(14, TableturfCardType.official), TableturfCardIdentifier(24, TableturfCardType.official), TableturfCardIdentifier(25, TableturfCardType.official), TableturfCardIdentifier(31, TableturfCardType.official), TableturfCardIdentifier(37, TableturfCardType.official), TableturfCardIdentifier(42, TableturfCardType.official), TableturfCardIdentifier(48, TableturfCardType.official), TableturfCardIdentifier(50, TableturfCardType.official), TableturfCardIdentifier(53, TableturfCardType.official), TableturfCardIdentifier(54, TableturfCardType.official), TableturfCardIdentifier(59, TableturfCardType.official), TableturfCardIdentifier(61, TableturfCardType.official), TableturfCardIdentifier(84, TableturfCardType.official), TableturfCardIdentifier(85, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Gnarly Eddy",
      map: "thunder_point",
      deck: TableturfDeck(
        deckID: -5,
        name: "Gnarly Eddy",
        cardSleeve: "gnarlyeddy",
        cards: [TableturfCardIdentifier(12, TableturfCardType.official), TableturfCardIdentifier(20, TableturfCardType.official), TableturfCardIdentifier(44, TableturfCardType.official), TableturfCardIdentifier(53, TableturfCardType.official), TableturfCardIdentifier(69, TableturfCardType.official), TableturfCardIdentifier(75, TableturfCardType.official), TableturfCardIdentifier(86, TableturfCardType.official), TableturfCardIdentifier(105, TableturfCardType.official), TableturfCardIdentifier(109, TableturfCardType.official), TableturfCardIdentifier(110, TableturfCardType.official), TableturfCardIdentifier(113, TableturfCardType.official), TableturfCardIdentifier(118, TableturfCardType.official), TableturfCardIdentifier(125, TableturfCardType.official), TableturfCardIdentifier(143, TableturfCardType.official), TableturfCardIdentifier(161, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Jel La Fleur",
      map: "square_squared",
      deck: TableturfDeck(
        deckID: -6,
        name: "Jel La Fleur",
        cardSleeve: "jellafleur",
        cards: [TableturfCardIdentifier(64, TableturfCardType.official), TableturfCardIdentifier(73, TableturfCardType.official), TableturfCardIdentifier(87, TableturfCardType.official), TableturfCardIdentifier(105, TableturfCardType.official), TableturfCardIdentifier(106, TableturfCardType.official), TableturfCardIdentifier(108, TableturfCardType.official), TableturfCardIdentifier(111, TableturfCardType.official), TableturfCardIdentifier(112, TableturfCardType.official), TableturfCardIdentifier(113, TableturfCardType.official), TableturfCardIdentifier(114, TableturfCardType.official), TableturfCardIdentifier(115, TableturfCardType.official), TableturfCardIdentifier(117, TableturfCardType.official), TableturfCardIdentifier(118, TableturfCardType.official), TableturfCardIdentifier(119, TableturfCardType.official), TableturfCardIdentifier(128, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Mr. Coco",
      map: "square_squared",
      deck: TableturfDeck(
        deckID: -7,
        name: "Mr. Coco",
        cardSleeve: "mrcoco",
        cards: [TableturfCardIdentifier(10, TableturfCardType.official), TableturfCardIdentifier(23, TableturfCardType.official), TableturfCardIdentifier(31, TableturfCardType.official), TableturfCardIdentifier(38, TableturfCardType.official), TableturfCardIdentifier(40, TableturfCardType.official), TableturfCardIdentifier(41, TableturfCardType.official), TableturfCardIdentifier(62, TableturfCardType.official), TableturfCardIdentifier(81, TableturfCardType.official), TableturfCardIdentifier(88, TableturfCardType.official), TableturfCardIdentifier(105, TableturfCardType.official), TableturfCardIdentifier(113, TableturfCardType.official), TableturfCardIdentifier(114, TableturfCardType.official), TableturfCardIdentifier(131, TableturfCardType.official), TableturfCardIdentifier(135, TableturfCardType.official), TableturfCardIdentifier(154, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Harmony",
      map: "lakefront_property",
      deck: TableturfDeck(
        deckID: -8,
        name: "Harmony",
        cardSleeve: "harmony",
        cards: [TableturfCardIdentifier(20, TableturfCardType.official), TableturfCardIdentifier(30, TableturfCardType.official), TableturfCardIdentifier(40, TableturfCardType.official), TableturfCardIdentifier(67, TableturfCardType.official), TableturfCardIdentifier(68, TableturfCardType.official), TableturfCardIdentifier(80, TableturfCardType.official), TableturfCardIdentifier(89, TableturfCardType.official), TableturfCardIdentifier(114, TableturfCardType.official), TableturfCardIdentifier(116, TableturfCardType.official), TableturfCardIdentifier(119, TableturfCardType.official), TableturfCardIdentifier(129, TableturfCardType.official), TableturfCardIdentifier(138, TableturfCardType.official), TableturfCardIdentifier(146, TableturfCardType.official), TableturfCardIdentifier(147, TableturfCardType.official), TableturfCardIdentifier(155, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Judd",
      map: "x_marks_the_garden",
      deck: TableturfDeck(
        deckID: -9,
        name: "Judd",
        cardSleeve: "judd",
        cards: [TableturfCardIdentifier(6, TableturfCardType.official), TableturfCardIdentifier(16, TableturfCardType.official), TableturfCardIdentifier(23, TableturfCardType.official), TableturfCardIdentifier(25, TableturfCardType.official), TableturfCardIdentifier(29, TableturfCardType.official), TableturfCardIdentifier(35, TableturfCardType.official), TableturfCardIdentifier(43, TableturfCardType.official), TableturfCardIdentifier(59, TableturfCardType.official), TableturfCardIdentifier(63, TableturfCardType.official), TableturfCardIdentifier(70, TableturfCardType.official), TableturfCardIdentifier(101, TableturfCardType.official), TableturfCardIdentifier(102, TableturfCardType.official), TableturfCardIdentifier(160, TableturfCardType.official), TableturfCardIdentifier(161, TableturfCardType.official), TableturfCardIdentifier(162, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Li'l Judd",
      map: "double_gemini",
      deck: TableturfDeck(
        deckID: -10,
        name: "Li'l Judd",
        cardSleeve: "liljudd",
        cards: [TableturfCardIdentifier(79, TableturfCardType.official), TableturfCardIdentifier(91, TableturfCardType.official), TableturfCardIdentifier(102, TableturfCardType.official), TableturfCardIdentifier(93, TableturfCardType.official), TableturfCardIdentifier(141, TableturfCardType.official), TableturfCardIdentifier(142, TableturfCardType.official), TableturfCardIdentifier(144, TableturfCardType.official), TableturfCardIdentifier(145, TableturfCardType.official), TableturfCardIdentifier(146, TableturfCardType.official), TableturfCardIdentifier(147, TableturfCardType.official), TableturfCardIdentifier(148, TableturfCardType.official), TableturfCardIdentifier(149, TableturfCardType.official), TableturfCardIdentifier(150, TableturfCardType.official), TableturfCardIdentifier(157, TableturfCardType.official), TableturfCardIdentifier(155, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Murch",
      map: "lakefront_property",
      deck: TableturfDeck(
        deckID: -11,
        name: "Murch",
        cardSleeve: "murch",
        cards: [TableturfCardIdentifier(26, TableturfCardType.official), TableturfCardIdentifier(33, TableturfCardType.official), TableturfCardIdentifier(50, TableturfCardType.official), TableturfCardIdentifier(51, TableturfCardType.official), TableturfCardIdentifier(59, TableturfCardType.official), TableturfCardIdentifier(65, TableturfCardType.official), TableturfCardIdentifier(66, TableturfCardType.official), TableturfCardIdentifier(68, TableturfCardType.official), TableturfCardIdentifier(76, TableturfCardType.official), TableturfCardIdentifier(90, TableturfCardType.official), TableturfCardIdentifier(103, TableturfCardType.official), TableturfCardIdentifier(104, TableturfCardType.official), TableturfCardIdentifier(108, TableturfCardType.official), TableturfCardIdentifier(119, TableturfCardType.official), TableturfCardIdentifier(136, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Shiver",
      map: "river_drift",
      deck: TableturfDeck(
        deckID: -12,
        name: "Shiver",
        cardSleeve: "shiver",
        cards: [TableturfCardIdentifier(52, TableturfCardType.official), TableturfCardIdentifier(53, TableturfCardType.official), TableturfCardIdentifier(59, TableturfCardType.official), TableturfCardIdentifier(68, TableturfCardType.official), TableturfCardIdentifier(69, TableturfCardType.official), TableturfCardIdentifier(82, TableturfCardType.official), TableturfCardIdentifier(98, TableturfCardType.official), TableturfCardIdentifier(99, TableturfCardType.official), TableturfCardIdentifier(100, TableturfCardType.official), TableturfCardIdentifier(127, TableturfCardType.official), TableturfCardIdentifier(132, TableturfCardType.official), TableturfCardIdentifier(133, TableturfCardType.official), TableturfCardIdentifier(147, TableturfCardType.official), TableturfCardIdentifier(148, TableturfCardType.official), TableturfCardIdentifier(152, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Frye",
      map: "main_street",
      deck: TableturfDeck(
        deckID: -13,
        name: "Frye",
        cardSleeve: "frye",
        cards: [TableturfCardIdentifier(54, TableturfCardType.official), TableturfCardIdentifier(55, TableturfCardType.official), TableturfCardIdentifier(57, TableturfCardType.official), TableturfCardIdentifier(61, TableturfCardType.official), TableturfCardIdentifier(72, TableturfCardType.official), TableturfCardIdentifier(98, TableturfCardType.official), TableturfCardIdentifier(99, TableturfCardType.official), TableturfCardIdentifier(100, TableturfCardType.official), TableturfCardIdentifier(122, TableturfCardType.official), TableturfCardIdentifier(124, TableturfCardType.official), TableturfCardIdentifier(135, TableturfCardType.official), TableturfCardIdentifier(137, TableturfCardType.official), TableturfCardIdentifier(145, TableturfCardType.official), TableturfCardIdentifier(151, TableturfCardType.official), TableturfCardIdentifier(159, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Big Man",
      map: "thunder_point",
      deck: TableturfDeck(
        deckID: -14,
        name: "Big Man",
        cardSleeve: "bigman",
        cards: [TableturfCardIdentifier(52, TableturfCardType.official), TableturfCardIdentifier(56, TableturfCardType.official), TableturfCardIdentifier(58, TableturfCardType.official), TableturfCardIdentifier(64, TableturfCardType.official), TableturfCardIdentifier(66, TableturfCardType.official), TableturfCardIdentifier(67, TableturfCardType.official), TableturfCardIdentifier(69, TableturfCardType.official), TableturfCardIdentifier(83, TableturfCardType.official), TableturfCardIdentifier(98, TableturfCardType.official), TableturfCardIdentifier(99, TableturfCardType.official), TableturfCardIdentifier(100, TableturfCardType.official), TableturfCardIdentifier(125, TableturfCardType.official), TableturfCardIdentifier(127, TableturfCardType.official), TableturfCardIdentifier(128, TableturfCardType.official), TableturfCardIdentifier(155, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Staff",
      map: "box_seats",
      deck: TableturfDeck(
        deckID: -15,
        name: "Staff",
        cardSleeve: "staff",
        cards: [TableturfCardIdentifier(3, TableturfCardType.official), TableturfCardIdentifier(18, TableturfCardType.official), TableturfCardIdentifier(39, TableturfCardType.official), TableturfCardIdentifier(56, TableturfCardType.official), TableturfCardIdentifier(57, TableturfCardType.official), TableturfCardIdentifier(58, TableturfCardType.official), TableturfCardIdentifier(61, TableturfCardType.official), TableturfCardIdentifier(62, TableturfCardType.official), TableturfCardIdentifier(63, TableturfCardType.official), TableturfCardIdentifier(64, TableturfCardType.official), TableturfCardIdentifier(67, TableturfCardType.official), TableturfCardIdentifier(69, TableturfCardType.official), TableturfCardIdentifier(74, TableturfCardType.official), TableturfCardIdentifier(92, TableturfCardType.official), TableturfCardIdentifier(121, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Cuttlefish",
      map: "x_marks_the_garden",
      deck: TableturfDeck(
        deckID: -16,
        name: "Cuttlefish",
        cardSleeve: "cuttlefish",
        cards: [TableturfCardIdentifier(1, TableturfCardType.official), TableturfCardIdentifier(32, TableturfCardType.official), TableturfCardIdentifier(77, TableturfCardType.official), TableturfCardIdentifier(93, TableturfCardType.official), TableturfCardIdentifier(94, TableturfCardType.official), TableturfCardIdentifier(95, TableturfCardType.official), TableturfCardIdentifier(120, TableturfCardType.official), TableturfCardIdentifier(121, TableturfCardType.official), TableturfCardIdentifier(122, TableturfCardType.official), TableturfCardIdentifier(124, TableturfCardType.official), TableturfCardIdentifier(127, TableturfCardType.official), TableturfCardIdentifier(134, TableturfCardType.official), TableturfCardIdentifier(139, TableturfCardType.official), TableturfCardIdentifier(140, TableturfCardType.official), TableturfCardIdentifier(159, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Agent 1",
      map: "square_squared",
      deck: TableturfDeck(
        deckID: -17,
        name: "Agent 1",
        cardSleeve: "callie",
        cards: [TableturfCardIdentifier(21, TableturfCardType.official), TableturfCardIdentifier(22, TableturfCardType.official), TableturfCardIdentifier(23, TableturfCardType.official), TableturfCardIdentifier(24, TableturfCardType.official), TableturfCardIdentifier(57, TableturfCardType.official), TableturfCardIdentifier(62, TableturfCardType.official), TableturfCardIdentifier(71, TableturfCardType.official), TableturfCardIdentifier(96, TableturfCardType.official), TableturfCardIdentifier(97, TableturfCardType.official), TableturfCardIdentifier(124, TableturfCardType.official), TableturfCardIdentifier(128, TableturfCardType.official), TableturfCardIdentifier(129, TableturfCardType.official), TableturfCardIdentifier(133, TableturfCardType.official), TableturfCardIdentifier(135, TableturfCardType.official), TableturfCardIdentifier(140, TableturfCardType.official)],
      )
  ),
  TableturfOpponent(
      name: "Agent 2",
      map: "river_drift",
      deck: TableturfDeck(
        deckID: -18,
        name: "Agent 2",
        cardSleeve: "marie",
        cards: [TableturfCardIdentifier(27, TableturfCardType.official), TableturfCardIdentifier(28, TableturfCardType.official), TableturfCardIdentifier(29, TableturfCardType.official), TableturfCardIdentifier(30, TableturfCardType.official), TableturfCardIdentifier(31, TableturfCardType.official), TableturfCardIdentifier(32, TableturfCardType.official), TableturfCardIdentifier(33, TableturfCardType.official), TableturfCardIdentifier(51, TableturfCardType.official), TableturfCardIdentifier(56, TableturfCardType.official), TableturfCardIdentifier(60, TableturfCardType.official), TableturfCardIdentifier(66, TableturfCardType.official), TableturfCardIdentifier(78, TableturfCardType.official), TableturfCardIdentifier(85, TableturfCardType.official), TableturfCardIdentifier(96, TableturfCardType.official), TableturfCardIdentifier(97, TableturfCardType.official)],
      )
  ),
];