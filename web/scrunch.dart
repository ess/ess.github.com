import 'dart:html';
import '../lib/game.dart';

void main() {
  Game game = new Game();
  game.start();
  document.on.keyDown.add(game.handleKey);
  document.on.keyUp.add(game.handleKey);
}
