package main

import "core:bytes"
import "core:strings"
import "core:testing"
import "src:git"

GROUP_SEPARATOR :: ". "
CHANGE_SEPARATOR :: ", "
CHANGE_FINAL_SEPARATOR :: " and "
RENAMED_SEPATOR :: " to "

Changes :: [git.Status_Code][dynamic]string

changes_init :: proc(changes: ^Changes, allocator := context.allocator) {
	for &changes in changes {
		changes = make([dynamic]string, 0, 5, allocator)
	}
}

changes_destroy :: proc(changes: ^Changes, allocator := context.allocator) {
	for c in changes {
		delete(c)
	}
}

changes_parse :: proc(changes: ^Changes, input: []byte, allocator := context.allocator) {
	status_code: git.Status_Code
	file: string
	start, end: int

	for start < len(input) - 1 {
		end = index_rune(input, start) or_break
		status_code = git.status_code_from_byte(input[start])

		defer start = end + 1

		if (status_code == .Unknown) {
			continue
		}

		defer append(&changes[status_code], file)
		start += 3

		if (status_code == .Renamed) {
			to_file := input[start:end]
			end += 1

			next_end := index_rune(input, end) or_break
			from_file := input[end:next_end]

			file = strings.concatenate(
				{string(from_file), RENAMED_SEPATOR, string(to_file)},
				allocator,
			)
			end = next_end

			continue
		}

		file = string(input[start:end])
	}
}

changes_create_message :: proc(changes: ^Changes, allocator := context.allocator) -> string {
	builder := strings.builder_make(0, git.MESSAGE_BODY_LEN, allocator)

	for status_changes, status_code in changes {
		status_changes_len := len(status_changes)
		if status_changes_len == 0 {
			continue
		}

		if strings.builder_len(builder) > 0 {
			strings.write_string(&builder, GROUP_SEPARATOR)
		}

		strings.write_string(&builder, git.Status_Code_Verbs[status_code])
		strings.write_string(&builder, status_changes[0])

		if status_changes_len > 1 {
			for change in status_changes[1:status_changes_len - 1] {
				strings.write_string(&builder, CHANGE_SEPARATOR)
				strings.write_string(&builder, change)
			}

			strings.write_string(&builder, CHANGE_FINAL_SEPARATOR)
			strings.write_string(&builder, status_changes[status_changes_len - 1])
		}
	}

	return strings.to_string(builder)
}

index_rune :: proc(input: []u8, start: int) -> (int, bool) {
	end := bytes.index_rune(input[start:], 0)
	if end == -1 {
		return end, false
	}
	return end + start, true
}

@(test)
test_changes_create_message :: proc(t: ^testing.T) {
	tests := [?]struct {
		input:    string,
		expected: string,
	} {
		{input = "", expected = ""},
		{input = " A foo\x00", expected = ""},
		{input = "M  foo\x00", expected = "Modify foo"},
		{input = "A  foo\x00", expected = "Add foo"},
		{input = "D  foo\x00", expected = "Delete foo"},
		{input = "C  foo\x00", expected = "Copy foo"},
		{input = "U  foo\x00", expected = "Update foo"},
		{input = "R  foo\x00bar\x00", expected = "Rename bar to foo"},
		{input = "A  foo\x00A  bar\x00", expected = "Add foo and bar"},
		{input = "A  foo\x00A  bar\x00A  foobar\x00", expected = "Add foo, bar and foobar"},
		{
			input = "A  foo\x00D  bar\x00M  foobar\x00",
			expected = "Modify foobar. Add foo. Delete bar",
		},
	}

	for tt in tests {
		grouped_changes: Changes
		changes_init(&grouped_changes)
		defer changes_destroy(&grouped_changes)

		input_bytes := transmute([]byte)tt.input

		changes_parse(&grouped_changes, input_bytes)

		message := changes_create_message(&grouped_changes)
		defer delete(message)

		testing.expect_value(t, message, tt.expected)

		// Only "Renamed" status entries allocate memory, so they should be freed after each run.
		// In production code, we don't need to worry about it because an arena is used to allocate the string.
		for r in grouped_changes[.Renamed] {
			delete(r)
		}
	}
}
