# Source of Mana

Client and Game development for Source of Mana, a The Mana World story.

## Tools

Game editor:
Godot current version is ['Godot 4.1'](https://github.com/godotengine/godot/releases/download/4.1-stable/Godot_v4.1-stable_win64.exe.zip) accessible on [Godot's official website](https://godotengine.org/download).

Level editor:
Tiled current version is ['Tiled 1.10.1'](https://www.mapeditor.org/2023/04/04/tiled-1-10-1-released.html) accessible on [Tiled's official website](https://www.mapeditor.org/).

DataBase editor:
SQLiteBrowser current version is ['3.12.2'](https://github.com/sqlitebrowser/sqlitebrowser)

## How to run the server

From source:
```
cd <checkout of this repo>
godot --server --headless
```

With prebuild binary:
```
"./Source of Mana" --server --headless
```

Note that SOM writes the list of online players next to the SOM or godot executable.

## License

This project is distributed under the terms of the MIT license, this includes every part of this repository except the data folder that is released under the CC BY-SA 4.0 license.
You can find describtion of such licenses  in the [LICENSE.md](LICENSE.md) file.
