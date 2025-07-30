package git

import os "core:os/os2"

DEFAULT_GIT_ERROR :: os.General_Error.Invalid_Command

diff :: proc(allocator := context.allocator) -> (out: []byte, err: os.Error) {
	reader, writer := os.pipe() or_return
	defer os.close(reader)

	process_desc := os.Process_Desc {
		command = {"git", "status", "--porcelain", "-z"},
		stdout  = writer,
		stderr  = os.stderr,
	}

	process := os.process_start(process_desc) or_return
	os.close(writer)

	state := os.process_wait(process) or_return
	check_state_error(state) or_return

	out = os.read_entire_file(reader, allocator) or_return

	return
}

commit :: proc(message: string) -> os.Error {
	return exec_commit(message, {"git", "commit", "--file=-"})
}

commit_edit :: proc(message: string) -> os.Error {
	return exec_commit(message, {"git", "commit", "--edit", "--file=-"})
}

@(private = "package")
exec_commit :: proc(message: string, command: []string) -> os.Error {
	reader, writer := os.pipe() or_return
	defer os.close(reader)

	process_desc := os.Process_Desc {
		command = command,
		stdin   = reader,
		stdout  = os.stdout,
		stderr  = os.stderr,
	}

	process := os.process_start(process_desc) or_return

	os.write_string(writer, message) or_return
	os.close(writer)

	state := os.process_wait(process) or_return

	return check_state_error(state)
}

@(private = "package")
check_state_error :: #force_inline proc(state: os.Process_State) -> os.Error {
	if !state.success || state.exit_code > 0 {
		return DEFAULT_GIT_ERROR
	}
	return nil
}
