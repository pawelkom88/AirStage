import Foundation

public protocol ImageSourcePicker {
    func pickImage(completion: @escaping (URL?) -> Void)
}
