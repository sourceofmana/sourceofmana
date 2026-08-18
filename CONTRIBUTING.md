# Contributing to Source of Mana

Thanks for wanting to help. Come [chat with us](README.md#community--contribution) before starting anything bigger than a trivial fix, so your work fits the plan and doesn't go to waste.

## Licensing

Code is MIT, art and design are CC BY-SA 4.0. See [LICENSE.md](LICENSE.md) for the details and per-file credits.

## Authorship

When you open a PR, you are the author. You own the work and take full responsibility for it. If we find it was taken from someone else without respecting their license or credit, the PR is removed. This holds whether the work was made with AI or not.

## Code

### Setup

Install [Godot](https://godotengine.org/) (see the [README](README.md#about-the-project) for the version we use), clone the repo, and open it. That's it.

Use whatever editor you like (Rider, VS Code, Vim...), but the result has to work in the Godot editor.

### Style

Follow Godot's [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) and use [static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html).

Two things we care about:
- **Names have meaning.** No `i`, no cryptic shorthand. Give loop indexes and everything else a real name.
- **Comment only when it's useful.** Don't narrate the code. Doc comments are required on API-level functions in `ServiceBase` files and on generic NPC functions.

## Assets

Ready-to-use assets, source files, and works in progress live in the [art design repository](https://github.com/sourceofmana/artdesign).

Tools we use:
- **Tiled**, our level editor: maps, NPCs, scripts, effects, collisions.
- **GIMP 3**, opens our layered `.xcf` source files.
- **Aseprite**, our pixel art editor.
- **Miro**, design, mechanics, lore, and story boards when planning a new chapter.

> We do not welcome AI-generated assets. Our game is hand-crafted: every pixel and tile is placed with a meaning. We'd rather respect our past and future artists than lean on generated assets.

## Game data

Use Godot's Game Data tab to view, add, and edit entries (items, skills, NPCs, and more). How-to guides will live in `docs/` (work in progress).

## Worldbuilding

The [designs/](designs) directory holds the lore. Read it before adding story or dialogue so the world stays consistent, and match its tone.

## Bug reports

Search existing issues first. If it's new, open one with clear steps to reproduce.

## Roadmap

We work in chapters, each one within its own milestone.
- **Milestone issues** are the focus for the next release.
- **Backlog issues** are open for anyone, not urgent. Look for `good first issue` and `help wanted`.

## Proposing a change

Talk to us on Discord or comment on an existing issue before you start anything. Your time is worth a lot, so let's make sure it goes where it's most useful. Even a small fix might have a better solution, and a change that doesn't fit the roadmap can be turned down no matter how good it is.

## Scope

We're a classic fantasy MMORPG with a 2D pixel art style. No guns, no lightsabers, nothing that goes against our [design direction](designs) as they are meant to define what belongs in the world.

## Testing

Play through your change in the Godot editor before opening a PR. If it touches anything network related, test it in multiplayer too. Watch for errors, failed asserts, and warnings, and clear them before sending.

## Pull requests

- Keep it focused: one topic per PR.
- Say what it does and why.
- No new assert or warnings, the project treats them as errors.
