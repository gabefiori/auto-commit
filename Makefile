SRC_DIR = src
OUT_NAME = auto-commit

CC = odin
CFLAGS = $(SRC_DIR) -collection:src=$(SRC_DIR) -out:$(OUT_NAME)

RELEASE_FLAGS = -o:speed -vet -strict-style -no-bounds-check -disable-assert
DEBUG_FLAGS = -debug
TEST_FLAGS = 

.PHONY: all release debug test clean run help

all: release

release:
	$(CC) build $(CFLAGS) $(RELEASE_FLAGS)

debug:
	$(CC) build $(CFLAGS) $(DEBUG_FLAGS)

test:
	$(CC) test $(CFLAGS) $(TEST_FLAGS)

clean:
	-@rm -f $(OUT_NAME)

run: release
	./$(OUT_NAME)

help:
	@echo "Available targets:"
	@echo "  all      : Build release version (default)"
	@echo "  release  : Build optimized release version"
	@echo "  debug    : Build with debug symbols"
	@echo "  test     : Run tests"
	@echo "  clean    : Remove build artifacts"
	@echo "  run      : Build and run the program"
	@echo "  help     : Show this help message"
