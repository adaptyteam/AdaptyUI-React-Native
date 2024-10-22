import Adapty
import AdaptyUI

extension AdaptyUI {
    struct View: Encodable {
        let id: String
        let paywallId: String
        let paywallVariationId: String

        enum CodingKeys: String, CodingKey {
            case id
            case paywallId = "paywall_id"
            case paywallVariationId = "paywall_variation_id"
        }
    }
}

@available(iOS 15.0, *)
extension AdaptyPaywallController {
    func toView() -> AdaptyUI.View {
            
        AdaptyUI.View(id: id.uuidString,
                      paywallId: paywall.placementId,
                      paywallVariationId: paywall.variationId)
    }
}
