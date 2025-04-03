# Source of Mana

Client and Game development for Source of Mana, a The Mana World story.

Both server and client save their data to `$XDG_DATA_HOME/SourceOfMana` on Linux or `\AppData\Roaming\SourceOfMana` on Windows or `~/Library/Application Support/SourceOfMana` on macOS.

## Tools

Game editor:
Godot current version is ['Godot 4.4.1'](https://github.com/godotengine/godot/releases/tag/4.4.1-stable) accessible on [Godot's official website](https://godotengine.org/download).

Level editor:
Tiled current version is ['Tiled 1.11.2'](https://www.mapeditor.org/2025/01/28/tiled-1-11-2-released.html) accessible on [Tiled's official website](https://www.mapeditor.org/).

DataBase editor:
SQLiteBrowser current version is ['3.12.2'](https://github.com/sqlitebrowser/sqlitebrowser)

## How to run the server

From source:
```
cd <checkout of this repo>
godot --server --headless
```

With prebuilt binary:
```
"./Source of Mana" --server --headless
```

The server expects a fullchain certificate as `server.crt` and its private key as `server.key` in the root of its data directory, which is mentioned above.

The server accepts connections on port 6118 (tcp) and port 6119 (udp).

## License

This project is distributed under the terms of the MIT license, this includes every part of this repository except the data folder that is released under the CC BY-SA 4.0 license.
You can find describtion of such licenses  in the [LICENSE.md](LICENSE.md) file.
