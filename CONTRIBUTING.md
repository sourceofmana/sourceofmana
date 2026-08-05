# Contributing to Source of Mana

## Code

> [!IMPORTANT]
> Please [chat](README.md#Contact) with us before working on anything more than a simple and trivial bugfix.
> This is to ensure your work will actually be merged and that you will not be wasting your time.

### Setting up your environment

We are using [Godot](https://godotengine.org/). We strive to use the latest version if possible.
Look at [project.godot](project.godot), the value `config/features` will reveal which version we are currently using.

### Formatting and style

See Godot's [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

Use [static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html).

You are expected to add [documentation comments](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html)
wherever necessary.

For example, a function called `LogMessageToChat` is already mostly self-explanatory but especially the function parameters still benefit from such documentation comments.
A very short introduction to the function will also never hurt, as it helps to clarify the intended purpose of the function.

```gdscript
## Adds a message to the chat window.
## Uses [param message] for the message and [param category] as the category the message will be displayed in.
## See [enum Message.categories] for all possible categories.
func LogMessageToChat(message: String, category: String) -> void:
    pass

```

Take some inspiration from the [Zen of Python](https://peps.python.org/pep-0020/).

## Art

> [!CAUTION]
> We do not welcome AI "art".

See our [art design repository](https://github.com/sourceofmana/artdesign).

## Game content

We use [Tiled](mapeditor.org) to make maps.

The [designs/](/designs) directory contains lore information necessary for a consistent world.
