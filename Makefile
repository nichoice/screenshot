PROJECT = ScreenshotTool.xcodeproj
SCHEME = ScreenshotTool
DESTINATION = platform=macOS

generate:
	xcodegen generate

test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)'

test-only:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' -only-testing:$(TEST)
