import AppKit

final class EditorTopBarView: NSView {
    weak var overlayView: OverlayView?
    private var sizeLabel: NSTextField!
    private var zoomButton: NSButton!
    private var doneButton: NSButton?
    var onDone: (() -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = ToolbarLayout.bgColor.cgColor
        autoresizingMask = [.width, .minYMargin]

        sizeLabel = makeLabel("")
        sizeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        sizeLabel.textColor = ToolbarLayout.iconColor.withAlphaComponent(0.45)

        let cropButton = makeButton("crop", tooltip: L("Crop"), action: #selector(cropClicked))
        let flipHButton = makeButton(
            "arrow.left.and.right.righttriangle.left.righttriangle.right",
            tooltip: L("Flip Horizontal"),
            action: #selector(flipHClicked)
        )
        let flipVButton = makeButton(
            "arrow.up.and.down.righttriangle.up.righttriangle.down",
            tooltip: L("Flip Vertical"),
            action: #selector(flipVClicked)
        )

        zoomButton = NSButton()
        zoomButton.bezelStyle = .recessed
        zoomButton.isBordered = false
        zoomButton.title = "100% v"
        zoomButton.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        zoomButton.contentTintColor = ToolbarLayout.iconColor.withAlphaComponent(0.45)
        zoomButton.target = self
        zoomButton.action = #selector(zoomButtonClicked)

        let border = NSView()
        border.wantsLayer = true
        border.layer?.backgroundColor = NSColor(white: 0.25, alpha: 1.0).cgColor
        border.translatesAutoresizingMaskIntoConstraints = false
        addSubview(border)

        [sizeLabel, cropButton, flipHButton, flipVButton, zoomButton].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32),

            sizeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            sizeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            cropButton.leadingAnchor.constraint(equalTo: sizeLabel.trailingAnchor, constant: 16),
            cropButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cropButton.widthAnchor.constraint(equalToConstant: 24),
            cropButton.heightAnchor.constraint(equalToConstant: 22),

            flipHButton.leadingAnchor.constraint(equalTo: cropButton.trailingAnchor, constant: 4),
            flipHButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            flipHButton.widthAnchor.constraint(equalToConstant: 24),
            flipHButton.heightAnchor.constraint(equalToConstant: 22),

            flipVButton.leadingAnchor.constraint(equalTo: flipHButton.trailingAnchor, constant: 4),
            flipVButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            flipVButton.widthAnchor.constraint(equalToConstant: 24),
            flipVButton.heightAnchor.constraint(equalToConstant: 22),

            zoomButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            zoomButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeButton(_ symbol: String, tooltip: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.bezelStyle = .recessed
        button.isBordered = false
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: tooltip)?
            .withSymbolConfiguration(.init(pointSize: 13, weight: .medium))
        button.contentTintColor = ToolbarLayout.iconColor.withAlphaComponent(0.85)
        button.toolTip = tooltip
        button.target = self
        button.action = action
        return button
    }

    private func makeLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }

    func updateSizeLabel(width: Int, height: Int) {
        sizeLabel.stringValue = "\(width) x \(height)"
    }

    func updateZoom(_ magnification: CGFloat) {
        zoomButton.title = "\(Int(magnification * 100))% v"
    }

    func showDoneButton() {
        guard doneButton == nil else { return }
        let button = NSButton()
        button.bezelStyle = .recessed
        button.isBordered = true
        button.title = L("Done")
        button.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        button.contentTintColor = ToolbarLayout.accentColor
        button.target = self
        button.action = #selector(doneClicked)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: zoomButton.leadingAnchor, constant: -12),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        doneButton = button
    }

    @objc private func doneClicked() {
        onDone?()
    }

    @objc private func zoomButtonClicked() {
        let menu = NSMenu()
        let presets: [(String, CGFloat)] = [
            ("50%", 0.5),
            ("100%", 1.0),
            ("200%", 2.0),
        ]

        for (title, magnification) in presets {
            let item = NSMenuItem(title: title, action: #selector(zoomPresetAction(_:)), keyEquivalent: "")
            item.target = self
            item.tag = Int(magnification * 100)
            menu.addItem(item)
        }

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: zoomButton.bounds.height + 2), in: zoomButton)
    }

    @objc private func zoomPresetAction(_ sender: NSMenuItem) {
        let magnification = CGFloat(sender.tag) / 100.0
        guard let scrollView = overlayView?.enclosingScrollView else { return }
        scrollView.magnification = magnification
        updateZoom(magnification)
    }

    @objc private func cropClicked() {
        guard let overlayView else { return }
        overlayView.currentTool = overlayView.currentTool == .crop ? .arrow : .crop
        overlayView.rebuildToolbarLayout()
        overlayView.needsDisplay = true
    }

    @objc private func flipHClicked() {
        overlayView?.flipImageHorizontally()
    }

    @objc private func flipVClicked() {
        overlayView?.flipImageVertically()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }
}
