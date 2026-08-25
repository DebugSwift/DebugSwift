# DebugSwift — quick build & run on the iOS Simulator
#
# A generic, zero-config Makefile for building, installing, and running the
# Example app on the booted iOS Simulator. Every value is overridable from the
# command line (`make run SIM_ID=… BUNDLE_ID=…`) or your environment.
#
# Usage:
#   make run          # build → install → launch (fastest path to running app)
#   make build        # build only
#   make install      # install the latest build to the booted simulator
#   make launch       # launch the app (must already be installed)
#   make terminate    # kill the running app
#   make booted       # print UDID + name of the booted simulator
#   make path         # print the resolved .app path
#   make clean        # clean build products
#   make open         # open the Simulator.app window
#
# Overrides:
#   SIM_ID      UDID of the simulator (default: first booted device)
#   BUNDLE_ID   bundle identifier of the app (default: Example's)
#   SCHEME      Xcode scheme to build (default: Example)
#   PROJECT     path to the .xcodeproj (default: Example/Example.xcodeproj)
#   DERIVED     derived-data path (default: a sibling of the project)

# ── Config (all overridable) ─────────────────────────────────────────────
SIM_ID     ?= $(shell xcrun simctl list devices booted -j | python3 -c 'import sys,json; d=json.load(sys.stdin)["devices"]; u=[x["udid"] for v in d.values() for x in v if x["state"]=="Booted"]; print(u[0] if u else "")')
BUNDLE_ID  ?= com.maatheusgois.debugswift.Example
SCHEME     ?= Example
PROJECT    ?= Example/Example.xcodeproj
CONFIG     ?= Debug
DERIVED    ?= $(PWD)/build/DerivedData

# .app lives under <DERIVED>/Build/Products/<CONFIG>-iphonesimulator/<SCHEME>.app
APP_PATH   := $(DERIVED)/Build/Products/$(CONFIG)-iphonesimulator/$(SCHEME).app

# ── Rules ─────────────────────────────────────────────────────────────────
.PHONY: build install launch run terminate booted path clean open help danger danger-setup danger-local danger-ci

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Build the scheme for the simulator
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-destination 'platform=iOS Simulator,id=$(SIM_ID)' \
		-derivedDataPath $(DERIVED) \
		build 2>&1 | tail -5

install: ## Install the built app to the booted simulator
	xcrun simctl install $(SIM_ID) "$(APP_PATH)"

launch: ## Launch the app on the booted simulator
	@PID=$$(xcrun simctl launch $(SIM_ID) $(BUNDLE_ID) 2>&1 | sed 's/.*: //'); echo "✓ App launched (PID: $$PID)"

run: build install launch ## Build, install, and launch

terminate: ## Kill the running app
	xcrun simctl terminate $(SIM_ID) $(BUNDLE_ID)

booted: ## Print the booted simulator UDID and name
	@xcrun simctl list devices booted | grep -v '^==' | grep -v '^$$'

path: ## Print the resolved .app path
	@echo "$(APP_PATH)"

open: ## Open the Simulator app window
	@open -a Simulator

clean: ## Remove build products
	rm -rf $(DERIVED)/Build/Products

# ── Danger ────────────────────────────────────────────────────────────────
danger-setup: ## Clone DangerSwift deps so swift build can compile Dangerfile
	@cp Package.swift /tmp/DebugSwift-Package.swift.bak; \
	git clone --depth 1 https://github.com/DebugSwift/DangerSwift /tmp/DangerSwift-clone 2>/dev/null; \
	rm -rf /tmp/DangerSwift-clone/.git /tmp/DangerSwift-clone/Readme.md; \
	cp /tmp/DangerSwift-clone/Package.swift .; \
	mkdir -p Sources/DangerDependencies; \
	touch Sources/DangerDependencies/placeholder.swift; \
	rm -rf /tmp/DangerSwift-clone; \
	echo "✓ DangerSwift Package.swift installed (original backed up to /tmp/DebugSwift-Package.swift.bak)"

danger-restore: ## Restore the original Package.swift after danger runs
	@mv -f /tmp/DebugSwift-Package.swift.bak Package.swift 2>/dev/null; \
	rm -rf Sources/DangerDependencies; \
	echo "✓ Package.swift restored"

danger-local: danger-setup ## Run danger-swift local (setup + build + run)
	swift build && swift run danger-swift local; make danger-restore

danger-ci: danger-setup ## Run danger-swift ci (setup + build + run)
	swift build && swift run danger-swift ci --verbose; make danger-restore

