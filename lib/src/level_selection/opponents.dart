class TableturfOpponent {
  final String name;
  final String sleeveDesign;
  final String map;
  final List<int> deck;

  const TableturfOpponent({
    required this.name,
    required this.sleeveDesign,
    required this.map,
    required this.deck,
  });
}

const List<TableturfOpponent> opponents = [
  TableturfOpponent(
    name: "Baby Jelly",
    sleeveDesign: "default",
    map: "main_street",
    deck: [5, 12, 21, 27, 33, 39, 44, 51, 54, 55, 91, 102, 136, 140, 158],
  ),
  TableturfOpponent(
    name: "Cool Jelly",
    sleeveDesign: "default",
    map: "main_street",
    deck: [2, 4, 7, 26, 36, 48, 56, 106, 113, 116, 119, 122, 129, 141, 155],
  ),
  TableturfOpponent(
    name: "Aggro Jelly",
    sleeveDesign: "default",
    map: "thunder_point",
    deck: [8, 9, 14, 16, 23, 25, 35, 40, 42, 46, 53, 110, 125, 131, 150],
  ),
  TableturfOpponent(
    name: "Sheldon",
    sleeveDesign: "sheldon",
    map: "x_marks_the_garden",
    deck: [9, 13, 23, 24, 30, 36, 41, 47, 49, 52, 53, 58, 60, 83, 84],
  ),
  TableturfOpponent(
    name: "Gnarly Eddy",
    sleeveDesign: "gnarlyeddy",
    map: "thunder_point",
    deck: [11, 19, 43, 52, 68, 74, 85, 104, 108, 109, 112, 117, 124, 142, 160],
  ),
  TableturfOpponent(
    name: "Jel La Fleur",
    sleeveDesign: "jellafleur",
    map: "square_squared",
    deck: [63, 72, 86, 104, 105, 107, 110, 111, 112, 113, 114, 116, 117, 118, 127],
  ),
  TableturfOpponent(
    name: "Mr. Coco",
    sleeveDesign: "mrcoco",
    map: "square_squared",
    deck: [9, 22, 30, 37, 39, 40, 61, 80, 87, 104, 112, 113, 130, 134, 153],
  ),
  TableturfOpponent(
    name: "Harmony",
    sleeveDesign: "harmony",
    map: "lakefront_property",
    deck: [19, 29, 39, 66, 67, 79, 88, 113, 115, 118, 128, 137, 145, 146, 154],
  ),
  TableturfOpponent(
    name: "Judd",
    sleeveDesign: "judd",
    map: "x_marks_the_garden",
    deck: [5, 15, 22, 24, 28, 34, 42, 58, 62, 69, 100, 101, 159, 160, 161],
  ),
  TableturfOpponent(
    name: "Li'l Judd",
    sleeveDesign: "liljudd",
    map: "double_gemini",
    deck: [78, 90, 101, 92, 140, 141, 143, 144, 145, 146, 147, 148, 149, 156, 154],
  ),
  TableturfOpponent(
    name: "Murch",
    sleeveDesign: "murch",
    map: "lakefront_property",
    deck: [25, 32, 49, 50, 58, 64, 65, 67, 75, 89, 102, 103, 107, 118, 135],
  ),
  TableturfOpponent(
    name: "Shiver",
    sleeveDesign: "shiver",
    map: "river_drift",
    deck: [51, 52, 58, 67, 68, 81, 97, 98, 99, 126, 131, 132, 146, 147, 151],
  ),
  TableturfOpponent(
    name: "Frye",
    sleeveDesign: "frye",
    map: "main_street",
    deck: [53, 54, 56, 60, 71, 97, 98, 99, 121, 123, 134, 136, 144, 150, 158],
  ),
  TableturfOpponent(
    name: "Big Man",
    sleeveDesign: "bigman",
    map: "thunder_point",
    deck: [51, 55, 57, 63, 65, 66, 68, 82, 97, 98, 99, 124, 126, 127, 154],
  ),
  TableturfOpponent(
    name: "Staff",
    sleeveDesign: "staff",
    map: "box_seats",
    deck: [2, 17, 38, 55, 56, 57, 60, 61, 62, 63, 66, 68, 73, 91, 120],
  ),
  TableturfOpponent(
    name: "Cuttlefish",
    sleeveDesign: "cuttlefish",
    map: "x_marks_the_garden",
    deck: [0, 31, 76, 92, 93, 94, 119, 120, 121, 123, 126, 133, 138, 139, 158],
  ),
  TableturfOpponent(
    name: "Agent 1",
    sleeveDesign: "callie",
    map: "square_squared",
    deck: [20, 21, 22, 23, 56, 61, 70, 95, 96, 123, 127, 128, 132, 134, 139],
  ),
  TableturfOpponent(
    name: "Agent 2",
    sleeveDesign: "marie",
    map: "river_drift",
    deck: [26, 27, 28, 29, 30, 31, 32, 50, 55, 59, 65, 77, 84, 95, 96],
  ),
  TableturfOpponent(
    name: "Clone Jelly",
    sleeveDesign: "default",
    map: "main_street",
    deck: [],
  ),
];