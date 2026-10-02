# pipefail rides on SHELL: macOS ships GNU Make 3.81, which ignores .SHELLFLAGS.
SHELL := /bin/bash -o pipefail

.PHONY: lint lint-fix format check setup-hooks build build-catalyst build-host test test-filter example example-catalyst docs migrate clean

# The local default pins the iOS 26.2 simulator runtime: with only Xcode 27 installed, add that runtime
# (Xcode > Settings > Components) or override DEST. CI omits OS= so the image's newest runtime is used.
DEST ?= platform=iOS Simulator,name=iPhone 17,OS=26.2
CATALYST_DEST = platform=macOS,variant=Mac Catalyst
XCB = xcodebuild -scheme LumiKit-Package -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO
XCB_EXAMPLE = xcodebuild -project Example/LumiKitExample.xcodeproj -scheme LumiKitExample -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO
LOG_DIR = build/logs

# pipefail (set above) keeps xcodebuild's exit status even though the output is piped through tail;
# the full log is kept under build/logs for the failure cases.

lint:
	swiftlint

lint-fix:
	swiftlint --fix

format:
	swiftformat .

check:
	swiftlint --strict
	swiftformat --lint .

setup-hooks:
	git config core.hooksPath Scripts/git-hooks
	@echo "Git hooks configured to Scripts/git-hooks/"

build:
	@mkdir -p $(LOG_DIR)
	$(XCB) build -destination '$(DEST)' 2>&1 | tee $(LOG_DIR)/build-ios.log | tail -5

build-catalyst:
	@mkdir -p $(LOG_DIR)
	$(XCB) build -destination '$(CATALYST_DEST)' 2>&1 | tee $(LOG_DIR)/build-catalyst.log | tail -5

test:
	@mkdir -p $(LOG_DIR)
	$(XCB) test -destination '$(DEST)' 2>&1 | tee $(LOG_DIR)/test-ios.log | tail -20

# FILTER=LumiKitUITests/LMKToastViewTests (or .../methodName)
test-filter:
	@mkdir -p $(LOG_DIR)
	$(XCB) test -destination '$(DEST)' -only-testing:$(FILTER) 2>&1 | tee $(LOG_DIR)/test-filter.log | tail -20

# Fast lane: the Foundation-only targets build natively on macOS (`swift test` links every test
# target into one bundle, so the UIKit targets keep native tests off the table).
build-host:
	swift build --target LumiKitCore
	swift build --target LumiKitDebug

example:
	@mkdir -p $(LOG_DIR)
	cd Example && xcodegen generate
	$(XCB_EXAMPLE) build -destination '$(DEST)' 2>&1 | tee $(LOG_DIR)/build-example.log | tail -5

# The Example app builds for the Mac idiom too (docs/PLATFORM.md rule 5); CI runs both lanes.
example-catalyst:
	@mkdir -p $(LOG_DIR)
	cd Example && xcodegen generate
	$(XCB_EXAMPLE) build -destination '$(CATALYST_DEST)' 2>&1 | tee $(LOG_DIR)/build-example-catalyst.log | tail -5

docs:
	@mkdir -p $(LOG_DIR)
	xcodebuild docbuild -scheme LumiKit-Package -destination 'generic/platform=iOS' -derivedDataPath build/docc -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO OTHER_DOCC_FLAGS=--warnings-as-errors 2>&1 | tee $(LOG_DIR)/docs.log | tail -5

# CONSUMER=../MyApp ARGS=--dry-run
migrate:
	Scripts/migrate-1.0.sh "$(CONSUMER)" $(ARGS)

clean:
	rm -rf .build build Example/build
