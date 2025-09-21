SDK := $(shell xcrun --show-sdk-path --sdk macosx)
CC  := clang
CFLAGS := -fobjc-arc -isysroot $(SDK)

FRAMEWORKS_LIST   := -framework Foundation -F /System/Library/PrivateFrameworks -framework MonitorPanel
FRAMEWORKS_TOGGLE := -framework Foundation -F /System/Library/PrivateFrameworks -framework MonitorPanel
FRAMEWORKS_KEY    := -framework AppKit -framework QuartzCore -framework Carbon

# Sources and binaries
SRC_LIST   := list_presets.m
SRC_TOGGLE := toggle_preset.m
SRC_KEY    := toggle_preset_hotkey.m

BIN_LIST   := list_presets
BIN_TOGGLE := toggle_preset
BIN_KEY    := toggle_preset_hotkey

.PHONY: all clean run-list run-toggle run-key

all: $(BIN_LIST) $(BIN_TOGGLE) $(BIN_KEY)

$(BIN_LIST): $(SRC_LIST)
	$(CC) $(CFLAGS) $(SRC_LIST) -o $(BIN_LIST) $(FRAMEWORKS_LIST)

$(BIN_TOGGLE): $(SRC_TOGGLE)
	$(CC) $(CFLAGS) $(SRC_TOGGLE) -o $(BIN_TOGGLE) $(FRAMEWORKS_TOGGLE)

$(BIN_KEY): $(SRC_KEY)
	$(CC) $(CFLAGS) $(SRC_KEY) -o $(BIN_KEY) $(FRAMEWORKS_KEY)

run-list: $(BIN_LIST)
	./$(BIN_LIST)

run-toggle: $(BIN_TOGGLE)
	./$(BIN_TOGGLE)

run-key: $(BIN_KEY)
	./$(BIN_KEY)

clean:
	rm -f $(BIN_LIST) $(BIN_TOGGLE) $(BIN_KEY)
