SWIFT_PKG = AirStage
EXECUTABLE = AirStageApp

.PHONY: all build run test clean release distribute clear reset

all: build

build:
	swift build --package-path $(SWIFT_PKG)

run:
	swift run --package-path $(SWIFT_PKG) $(EXECUTABLE)

test:
	swift test --package-path $(SWIFT_PKG)

release:
	swift build --package-path $(SWIFT_PKG) -c release
	cp -R "$(SWIFT_PKG)/.build/release/$(EXECUTABLE).app" "Release/$(EXECUTABLE).app"

distribute: release
	./Packaging/create-dmg.sh

clean:
	swift package --package-path $(SWIFT_PKG) clean
	rm -rf Release dist

clear:
	-pkill -9 $(EXECUTABLE) 2>/dev/null || true
	defaults delete $(EXECUTABLE) 2>/dev/null || true
	@echo "Cleared UserDefaults for $(EXECUTABLE)"

reset: clear clean
	$(MAKE) build
	@echo "Reset complete. Run 'make run' to start fresh."
