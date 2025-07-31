package main

import "core:flags"
import "core:mem"
import "core:mem/virtual"
import os "core:os/os2"
import "src:git"

INVALID_MESSAGE :: `The generated commit message exceeds the recommended 50-character limit for git message titles.
Use the '--force' flag to bypass this validation and proceed with the longer message.
`


Options :: struct {
	dry_run: bool `usage:"Simulate the commit without actually creating one"`,
	edit:    bool `usage:"Open the default editor to modify the commit message before committing"`,
	force:   bool `usage:"Don’t fail if the generated commit message is invalid (e.g., longer than 50 characters)"`,
}

main :: proc() {
	exit_code: int
	arena: virtual.Arena

	defer {
		virtual.arena_destroy(&arena)
		os.exit(exit_code)
	}

	ensure(virtual.arena_init_growing(&arena) == nil)
	arena_allocator := virtual.arena_allocator(&arena)

	options: Options
	flags.parse_or_exit(&options, os.args, .Unix, arena_allocator)

	if err := run(options, arena_allocator); err != nil {
		exit_code = 1
	}
}

run :: proc(options: Options, arena_allocator: mem.Allocator) -> os.Error {
	status_output := git.status(arena_allocator) or_return

	changes: Changes
	changes_init(&changes, arena_allocator)
	changes_parse(&changes, status_output, arena_allocator)

	message := changes_create_message(&changes, arena_allocator)

	if !options.force && len(message) > git.MESSAGE_TITLE_LEN {
		os.write_string(os.stderr, INVALID_MESSAGE) or_return
		return os.General_Error.Unsupported
	}

	if options.dry_run {
		_, err := os.write_string(os.stdout, message)
		return err
	}

	if options.edit || len(message) > git.MESSAGE_TITLE_LEN {
		return git.commit_edit(message)
	}

	return git.commit(message)
}
