import Foundation

protocol FrontmostApplicationObserver: AnyObject {
    var onChange: ((String?) -> Void)? { get set }
    func start()
    func stop()
}
