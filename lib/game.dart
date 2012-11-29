library Game;

import "dart:html";
import "dart:math" as Math;
import "utils.dart";

part "game/camera.dart";
part "game/collision_field.dart";
part "game/message_controller.dart";
part "game/render.dart";
part "game/level.dart";
part "game/level_tile.dart";
part "game/render_object.dart";
part "game/render_object/game_object.dart";
part "game/render_object/player.dart";
part "game/render_object/door.dart";
part "game/render_object/flag.dart";
part "game/render_object/interactive_object.dart";
part "game/render_object/level_object.dart";
part "game/sprite.dart";
part "game/animation_frames.dart";

class Game {
  Render render;
  List<GameObject> gameobjects;
  Level level;
  Player player;
  Camera camera;
  MessageController messages;
  bool showCollisionField = false;
  PreLoader loader;
  bool stop = false;
  
  int currentlevel = 0;
  String levelsource;

  //framerate
  int frames = 0;
  double lastTime;
  double time = 0.0;
  int fps = 0;
  
  static final int GRAVITY = 8;

  Game() : render = new Render(), gameobjects = new List<GameObject>(), camera = new Camera() {
    level = new Level(this);
    player = new Player(this);
    messages = new MessageController();
  }

  void start() {
    loader = new PreLoader(loadingFinished);
    
    levelsource = "resources/levels/level_$currentlevel.json";

    //load resources
    loader.loadJson(levelsource);
    loader.loadImage("resources/images/images.png");
    loader.loadImage("resources/images/c0v0a16t1uv1t80Cs1Cd.png");
    loader.start();
  }
  
  void loadingFinished() {
    //when loading has finsished, display a start button
    ButtonElement dombutton = new ButtonElement();
    DivElement main = document.query("#openscreen");
    main.style.transition = "opacity 0.5s ease-in-out";

    document.query("#loading").text = "";
    
    dombutton.text = "Start!";
    
    //messy jquery style code YAY!
    dombutton.on.click.add((e) {
        main.style.opacity = "0.0";
        window.setTimeout(() {
          main.remove(); 
          startGame();
          }, 500);
        });
    main.nodes.add(dombutton);
  }
  
  void startGame() {
    //create sprites
    //create gameobjects
    level.start();
    camera.start(this);
    render.start(this);
    
    gameobjects.add(player);
    
    loadLevel();

    window.requestAnimationFrame(loop);
    
    messages.sendMessage("Hello there :). Messages will pop-up here.");
  }
  
  void loadLevel() {
    level.loadLevel(JsonController.getJson(levelsource));
    

    camera.w = 512;
    camera.h = 448;

    
    //verticaly center the game
    int offsettop = 38;
    if(camera.h == level.h)
      offsettop = ((window.innerHeight - 44 - camera.h)/2).toInt();
    
    render.layer.canvas.style.marginTop = "${offsettop}px";
    
    render.start(this);

    int minborder = Math.min(camera.w, camera.h);
    camera.border = (minborder*0.3).toInt(); //10%

    //place in middle of first tile
    player.reset(level.startx.toDouble(),level.starty.toDouble());
  }
  
  void resetLevel() {
    player.reset(level.startx.toDouble(),level.starty.toDouble());
  }
  
  void goToLevel(String location) {
    loader.callback = loadLevel;
    loader.reset();
    levelsource = location;
    
    loader.loadJson(levelsource);
    loader.start();
  }
  
  void goToLevelid(int id) {
    currentlevel = id;
    goToLevel("resources/levels/level_$currentlevel.json");
  }
  
  void goToNextLevel() {
    currentlevel++;
    goToLevel("resources/levels/level_$currentlevel.json");
  }

  void loop(double looptime) {
    if(stop != true) {
      if(lastTime == null)
        lastTime = looptime;

      update(looptime);

      //framerate
      double now = looptime;//(new Date.now()).value;
      double delta = now-lastTime;
      lastTime = now;
      time += delta;
      frames++;
      if(time > 1000) {
        fps = (1000*frames/time).toInt();
        time = 0.0;
        frames = 0;
      }
    
      window.requestAnimationFrame(loop);
    }
  }

  void update(double looptime) {
    for(int i = 0; i < gameobjects.length; i++)
      gameobjects[i].update(lastTime, looptime);

    render.update(lastTime, looptime);
  }
  
  void handleKey(KeyboardEvent event) {
    //event.preventDefault();
    int key = event.keyCode;
    bool down = event.type == "keydown";//event.KEYDOWN
    
    //print(key);

    if(key == 37 || key == 65)//left & a
      player.setMove(Player.MOVE_LEFT, down);
    if(key == 39 || key == 68)//right & d
      player.setMove(Player.MOVE_RIGHT,down);
    if(key == 38 || key == 87)//up & w
      player.setMove(Player.MOVE_JUMP, down);
    if(key == 40 || key == 83)//down & s
      player.setMove(Player.MOVE_JUMP2, down);
    
    if((key == 13 || key == 81) && down)//enter & q
      player.enterObject();
    if(key == 67 && down)//c
      showCollisionField = showCollisionField == false;
  }
}
