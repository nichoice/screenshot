import Foundation

final class AnnotationDocument: ObservableObject {
    @Published private(set) var items: [AnnotationItem] = []

    func add(_ item: AnnotationItem) {
        items.append(item)
    }

    func undo() {
        _ = items.popLast()
    }

    func clear() {
        items.removeAll()
    }
}
