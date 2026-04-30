import Foundation

enum InlineAnnotationToolbarItem: String, CaseIterable, Equatable {
    case rectangle
    case ellipse
    case emoji
    case arrow
    case pen
    case mosaic
    case text
    case ocr
    case undo
    case save
    case pin
    case edit
    case share
    case cancel
    case confirm
}

enum InlineAnnotationToolbarModel {
    static let defaultItems: [InlineAnnotationToolbarItem] = [
        .rectangle,
        .ellipse,
        .emoji,
        .arrow,
        .pen,
        .mosaic,
        .text,
        .undo,
        .save,
        .pin,
        .edit,
        .share,
        .cancel,
        .confirm
    ]

    static let groups: [[InlineAnnotationToolbarItem]] = [
        [.rectangle, .ellipse, .emoji, .arrow, .pen, .mosaic, .text],
        [.undo],
        [.save, .pin, .edit, .share],
        [.cancel, .confirm]
    ]
}
