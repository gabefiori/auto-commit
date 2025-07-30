# Auto Commit
Commit changes with auto-generated messages.

## Usage
By default, a hard limit of 50 characters is enforced to follow best practices for commit titles.
Use the `--force` flag to bypass this limit.

```sh
Usage:
        auto-commit [--dry-run] [--edit] [--force]
Flags:
        --dry-run  | Simulate the commit without actually creating one
        --edit     | Open the default editor to modify the commit message before committing
        --force    | Don’t fail if the generated commit message is invalid (e.g., longer than 50 characters)
```

### Examples:
To test the commit process without making any changes, run:
```sh
$ auto-commit --dry-run
Modify foo and bar
```

To create an actual commit, run:
```sh
$ auto-commit
[main 1f2a3b4] Add foo, bar and foobar
 3 files changed, 8 insertions(+)
```

## Build
Requires the [Odin compiler](https://odin-lang.org/) to be installed.

## Build Instructions
### Release Build
```sh
make release
```
Creates an optimized binary.

### Debug Build
```sh
make debug
```
Creates a build with debug symbols for development.
