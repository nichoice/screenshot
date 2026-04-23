import Combine
import Foundation

final class AnnotationDocument: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private(set) var items: [AnnotationItem] = []

    func add(_ item: AnnotationItem) {
        items.append(item)
        objectWillChange.send()
    }

    func undo() {
        _ = items.popLast()
        objectWillChange.send()
    }

    func clear() {
        items.removeAll()
        objectWillChange.send()
    }
}
