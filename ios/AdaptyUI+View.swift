import Adapty
import AdaptyUI

extension AdaptyUI {
    struct View: Encodable {
        let id: String
        let templateId: String
        let paywallId: String
        let paywallVariationId: String

        enum CodingKeys: String, CodingKey {
            case id
            case templateId = "template_id"
            case paywallId = "paywall_id"
            case paywallVariationId = "paywall_variation_id"
        }
    }
}

extension AdaptyPaywallController {
    func toView() -> AdaptyUI.View {
            
        AdaptyUI.View(id: id.uuidString,
                      templateId: viewConfiguration.templateId,
                      paywallId: paywall.placementId,
                      paywallVariationId: paywall.variationId)
    }
}
