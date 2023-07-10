# Source of Mana

Client and Game development for Source of Mana, a The Mana World story.

## Tools

Godot current version is ['Godot 4.0.3'](https://github.com/godotengine/godot/releases/download/4.0.3-stable/Godot_v4.0.3-stable_win64.exe.zip) accessible on [Godot's official website](https://godotengine.org/download).
Tiled current version is ['Tiled 1.10.1'](https://www.mapeditor.org/2023/04/04/tiled-1-10-1-released.html) accessible on [Tiled's official website](https://www.mapeditor.org/).

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
