import Foundation
import AdaptyUI


extension AdaptyViewResult<T: Encodable>: Encodable {
    public let data: T
    public let type: String
    public let view: AdaptyPaywallController
    
    enum CodingKeys: String, CodingKey {
        case data
        case type
        case viewId = "view_id"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(type, forKey: .type)
        try container.encode(view.toView().id, forKey: .viewId)
    }
    
}
