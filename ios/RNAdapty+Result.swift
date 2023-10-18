import Foundation
import AdaptyUI
import react_native_adapty_sdk

struct AdaptyViewResult<T: Encodable>: Encodable {
    var adaptyResult: AdaptyResult<T>
    var view: AdaptyPaywallController

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(adaptyResult.data, forKey: .data)
        try container.encode(adaptyResult.type, forKey: .type)
        try container.encode(view.toView().id, forKey: .view)
    }

    enum CodingKeys: String, CodingKey {
        case data, type, view
    }
}
