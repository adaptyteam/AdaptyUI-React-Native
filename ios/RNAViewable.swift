import Foundation
import AdaptyUI

struct Viewable<T: Encodable>: Encodable  {
    let payload: T?;
    let view: AdaptyPaywallController
    
    
    enum CodingKeys: String, CodingKey {
        case payload
        case _viewId = "_view_id"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payload, forKey: .payload)
        try container.encode(view.toView().id, forKey: ._viewId)
    }
}


