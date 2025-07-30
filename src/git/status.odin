package git

Status_Code :: enum {
	Unknown,
	Modified,
	Added,
	Deleted,
	Renamed,
	Copied,
	Updated,
}

status_code_from_byte :: proc(b: byte) -> Status_Code {
	switch b {
	case 'M':
		return .Modified
	case 'A':
		return .Added
	case 'D':
		return .Deleted
	case 'R':
		return .Renamed
	case 'C':
		return .Copied
	case 'U':
		return .Updated
	case:
		return .Unknown
	}
}

Status_Code_Verbs := [Status_Code]string {
	.Unknown      = "Unknown ",
	.Modified     = "Modify ",
	.Added        = "Add ",
	.Deleted      = "Delete ",
	.Renamed      = "Rename ",
	.Copied       = "Copy ",
	.Updated      = "Update ",
}
