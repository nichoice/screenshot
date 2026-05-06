import Cocoa

/// Tiny always-on-top control used by the MVP recording flow.
@MainActor
final class RecordingHUDPanel: NSPanel {
    var onStopRecording: (() -> Void)?

    private let timeLabel = NSTextField(labelWithString: "00:00")
    private let stopButton = NSButton()
    private var timer: Timer?
    private var elapsedSeconds = 0

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 128, height: 36),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar + 2
        hidesOnDeactivate = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let content = NSView(frame: NSRect(x: 0, y: 0, width: 128, height: 36))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.92).cgColor
        content.layer?.cornerRadius = 12
        content.layer?.borderWidth = 0.5
        content.layer?.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor
        contentView = content

        configureStopButton(in: content)
        configureTimeLabel(in: content)
    }

    override var canBecomeKey: Bool { false }

    func show(relativeTo screenRect: NSRect, screen: NSScreen) {
        positionOnScreen(relativeTo: screenRect, screen: screen)
        orderFrontRegardless()
        startTimer()
    }

    override func close() {
        timer?.invalidate()
        timer = nil
        super.close()
    }

    func positionOnScreen(relativeTo screenRect: NSRect, screen: NSScreen) {
        let gap: CGFloat = 10
        let visibleFrame = screen.visibleFrame
        let size = frame.size
        var origin = NSPoint(
            x: screenRect.maxX - size.width,
            y: screenRect.minY - size.height - gap
        )

        if origin.y < visibleFrame.minY {
            origin.y = screenRect.maxY + gap
        }
        origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - size.width - 8)
        origin.y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - size.height - 8)
        setFrameOrigin(origin)
    }

    private func configureStopButton(in content: NSView) {
        stopButton.frame = NSRect(x: 8, y: 6, width: 24, height: 24)
        stopButton.isBordered = false
        stopButton.image = NSImage(systemSymbolName: "stop.fill", accessibilityDescription: "Stop")
        stopButton.image = stopButton.image?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        )
        stopButton.contentTintColor = .systemRed
        stopButton.toolTip = L("Stop Recording")
        stopButton.target = self
        stopButton.action = #selector(stopClicked)
        content.addSubview(stopButton)
    }

    private func configureTimeLabel(in content: NSView) {
        timeLabel.frame = NSRect(x: 40, y: 8, width: 78, height: 20)
        timeLabel.alignment = .center
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        timeLabel.textColor = .labelColor
        timeLabel.drawsBackground = false
        timeLabel.isBezeled = false
        timeLabel.isEditable = false
        content.addSubview(timeLabel)
    }

    private func startTimer() {
        elapsedSeconds = 0
        updateTimeLabel()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.elapsedSeconds += 1
                self.updateTimeLabel()
            }
        }
    }

    private func updateTimeLabel() {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        timeLabel.stringValue = String(format: "%02d:%02d", minutes, seconds)
    }

    @objc private func stopClicked() {
        onStopRecording?()
    }
}
