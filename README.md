# Tableturf Mobile

A remake of Tableturf Battle in Flutter, designed for mobile devices. Also works on web.

Contains all official opponents/cards/maps of the original game, a deck builder, a custom map editor, and an AI to play against with multiple difficulties.

Use `flutter run` to run on a device.

## Todo list

- [x] Implement XP from battles
- [x] Implement unlocking opponents via ranks
- [x] Implement card bit rewards
- [x] Animate card bit rewards
- [x] Implement card packs
- [x] Optimise card flip animation in card pack
- [x] Optimise animating the deck popup in/out
- [x] Make the deck editor less shit to use
- [x] Make the bottom buttons in the map editor less shit
- [x] Screen for testing custom decks/boards
- [x] Change card bits out for coins, add a loss reward because i suck at my own game
- [x] Refactor game logic to use an MVC style approach to make gamemodes easier to add
- [ ] Add rendering different card levels (basic or full-on?)
- [ ] Add being able to see card levels in a match
- [-] Add buying cards to the card list screen (interface added, non-functional ATM)
- [ ] Make randomiser deck unlockable (probably also move it to earlier in the opponent list)
- [ ] Make the UI better able to handle different screen sizes
- [ ] Custom card creator
- [ ] Add final graphical effects to session start/end
- [ ] Add special point/passed turn counting
- [ ] Achievements?
- [ ] Add special tile distance awareness to AI alongside normal tile distance awareness? (different calculations per level?)
- [ ] Move all animation durations into a single global list of constants
- [ ] Multiplayer
