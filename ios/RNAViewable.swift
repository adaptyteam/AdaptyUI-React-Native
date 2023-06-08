import Foundation
import Adapty

struct Viewable<T: Encodable>: Encodable  {
    let payload: T;
    let view: AdaptyUI.View;
    
    
    enum CodingKeys: String, CodingKey {
        case payload
        case _viewId = "_view_id"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payload, forKey: .payload)
        try container.encode(view.id, forKey: ._viewId)
    }
}


