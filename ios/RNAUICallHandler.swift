import Foundation
import Adapty
import AdaptyUI
import react_native_adapty_sdk

extension UIViewController {
    var isOrContainsAdaptyController: Bool {
        guard let presentedViewController = presentedViewController else {
            return self is AdaptyPaywallController
        }
        return presentedViewController is AdaptyPaywallController
    }
}


@objc(RNAUICallHandler)
class RNAUICallHandler: RCTEventEmitter, AdaptyPaywallControllerDelegate {
    // MARK: - Config
    
    private var paywallControllers = [UUID: AdaptyPaywallController]()
    //    private static var adaptyUIDelegate: AdaptyUIDelegate!
    
    // TODO: Why
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    override func supportedEvents() -> [String]! {
        return [
            EventName.onCloseButtonPress.rawValue,
            EventName.onProductSelected.rawValue,
            EventName.onPurchaseStarted.rawValue,
            EventName.onPurchaseCancelled.rawValue,
            EventName.onPurchaseCompleted.rawValue,
            EventName.onPurchaseFailed.rawValue,
            EventName.onRestoreStarted.rawValue,
            EventName.onRestoreCompleted.rawValue,
            EventName.onRestoreFailed.rawValue,
            EventName.onRenderingFailed.rawValue,
            EventName.onLoadingProductsFailed.rawValue,
            EventName.onAction.rawValue,
            EventName.onCustomEvent.rawValue,
            EventName.onUrlPress.rawValue,
            EventName.onAndroidSystemBack.rawValue,
        ]
    }
    
    override func constantsToExport() -> [AnyHashable : Any]! {
        // Name of the function that routes all incoming requests
        return ["HANDLER": "handle"]
    }
    
    // MARK: - Private API
    
    // Do not send events to JS, when JS does not expect
    private var hasListeners = false
    
    override func startObserving() {
        self.hasListeners = true
    }
    override func stopObserving() {
        self.hasListeners = false
    }
    
    /// Sends event to JS layer if client has listeners
    private func pushEvent(_ event: EventName, view: AdaptyPaywallController) {
        if !hasListeners {
            return
        }
        
        let result = AdaptyViewResult(
            adaptyResult: AdaptyResult(data: NullEncodable(), type: "null"),
            view: view
        )
        
        guard let str = try? AdaptyContext.encodeToJSON(result)
        else {
            // TODO: Should not happen
            return self.pushEvent(event, view: view)
        }
        
        self.sendEvent(withName: event.rawValue, body: str)
    }
    
    /// Sends event to JS layer if client has listeners
    private func pushEvent<T: Encodable>(_ event: EventName, view: AdaptyPaywallController, data: T) {
        if !hasListeners {
            return
        }
        
        let result = AdaptyViewResult(
            adaptyResult: AdaptyResult(data: data, type: String(describing: T.self)),
            view: view
        )
        
        guard let str = try? AdaptyContext.encodeToJSON(result) else {
            // TODO: Should not happen
            return self.pushEvent(event, view: view)
        }
        
        self.sendEvent(withName: event.rawValue, body: str)
    }
    
    private func cachePaywallController(_ controller: AdaptyPaywallController, id: UUID) {
        paywallControllers[id] = controller
    }
    
    private func deleteCachedPaywallController(_ id: String) {
        guard let uuid = UUID(uuidString: id) else { return }
        paywallControllers.removeValue(forKey: uuid)
    }
    
    private func cachedPaywallController(_ id: String) -> AdaptyPaywallController? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return paywallControllers[uuid]
    }
    
    private func getConfigurationAndCreateView(
        ctx: AdaptyContext,
        paywall: AdaptyPaywall,
        preloadProducts: Bool,
        customTags: [String: String]?
    ) {
        AdaptyUI.getViewConfiguration(forPaywall: paywall) { result in
            switch result {
            case let .failure(error):
                return ctx.forwardError(error)
                
            case let .success(config):
                let vc = AdaptyUI.paywallController(
                    for: paywall,
                    products: nil,
                    viewConfiguration: config,
                    delegate: self,
                    tagResolver: customTags
                )
                
                self.cachePaywallController(vc, id: vc.id)
                
                return ctx.resolve(with: vc.id.uuidString)
            }
        }
    }
    
    // MARK: - Public handlers
    
    @objc public func handle(
        _ method: NSString,
        args: NSDictionary,
        resolver: @escaping RCTPromiseResolveBlock,
        rejecter: @escaping RCTPromiseRejectBlock
    ) {
        let ctx = AdaptyContext(
            args: args,
            resolver: resolver,
            rejecter: rejecter
        )
        
        do {
            switch MethodName(rawValue: method as String) ?? .notImplemented {
            case .createView:  try handleCreateView(ctx)
            case .presentView: try handlePresentView(ctx)
            case .dismissView: try handleDismissView(ctx)
                
            default: throw BridgeError.methodNotImplemented
            }
        } catch {
            ctx.bridgeError(error)
        }
    }
    
    private func handleCreateView(_ ctx: AdaptyContext) throws {
        let paywallStr: String = try ctx.params.getRequiredValue(for: .paywall)
        let preloadProducts: Bool? = ctx.params.getOptionalValue(for: .prefetch_products)
        let customTags: [String: String]? = try ctx.params.getDecodedOptionalValue(for: .custom_tags, jsonDecoder: AdaptyContext.jsonDecoder)
        
        guard let paywallData = paywallStr.data(using: .utf8),
              let paywall = try? AdaptyContext.jsonDecoder.decode(AdaptyPaywall.self, from: paywallData)
        else {
            throw BridgeError.typeMismatch(name: .paywall, type: "String")
        }
        
        
        getConfigurationAndCreateView(
            ctx: ctx,
            paywall: paywall,
            preloadProducts: preloadProducts ?? false,
            customTags: customTags
        )
    }
    
    private func handlePresentView(_ ctx: AdaptyContext) throws {
        let id: String = try ctx.params.getRequiredValue(for: .view_id)
        
        guard let vc = cachedPaywallController(id) else {
            throw BridgeError.typeMismatch(name: .view_id, type: "Failed to find cached view controller")
        }
        
        
        DispatchQueue.main.async {
            vc.modalPresentationCapturesStatusBarAppearance = true
            vc.modalPresentationStyle = .overFullScreen
            
            guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
                return ctx.bridgeError(
                    BridgeError.typeMismatch(name: .view_id, type: "Failed to find root view controller")
                )
                
            }
            
            guard !rootVC.isOrContainsAdaptyController else {
                return ctx.bridgeError(
                    BridgeError.typeMismatch(name: .view_id, type: "View already presented")
                )
            }
            
            rootVC.present(vc, animated: true) {
                ctx.resolve()
            }
        }
    }
    
    private func handleDismissView(_ ctx: AdaptyContext) throws {
        let id: String = try ctx.params.getRequiredValue(for: .view_id)
        
        guard let vc = cachedPaywallController(id) else {
            throw BridgeError.typeMismatch(
                name: .view_id,
                type: "Failed to find cached view controller"
            )
        }
        
        DispatchQueue.main.async {
            vc.dismiss(animated: true) { [weak self] in
                self?.deleteCachedPaywallController(id)
                
                return ctx.resolve()
            }
        }
    }
    
    // MARK: - Event Handlers
    func paywallController(_ controller: AdaptyPaywallController, didPerform action: AdaptyUI.Action) {
        self.pushEvent(EventName.onAction, view: controller)
        switch action {
        case .close:
            self.pushEvent(EventName.onCloseButtonPress, view: controller)
            break
        case let .openURL(url):
            self.pushEvent(.onUrlPress, view: controller, data: url.absoluteString)
            UIApplication.shared.open(url, options: [:])
            break
        case let .custom(id):
            self.pushEvent(.onCustomEvent, view: controller, data: id)
            break
            
        }
    }
    
    
    /// PRODUCT SELECTED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didSelectProduct product: AdaptyPaywallProduct) {
        self.pushEvent(EventName.onProductSelected, view: controller, data: product)
    }
    
    /// PURCHASE STARTED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didStartPurchase product: AdaptyPaywallProduct) {
        self.pushEvent(EventName.onPurchaseStarted, view: controller, data: product)
    }
    
    /// PURCHASE SUCCESS
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFinishPurchase product: AdaptyPaywallProduct,
                                  purchasedInfo: AdaptyPurchasedInfo) {
        self.pushEvent(EventName.onPurchaseCompleted, view: controller, data: purchasedInfo.profile)
    }
    
    /// RENDERING FAILED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailRenderingWith error: AdaptyError) {
        self.pushEvent(EventName.onRenderingFailed, view: controller, data: error)
    }
    
    /// LOAD PRODUCTS FAILED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailLoadingProductsWith error: AdaptyError) -> Bool {
        self.pushEvent(EventName.onLoadingProductsFailed, view: controller, data: error)
        
        return true
    }
    
    /// PURCHASE FAILED
    func paywallController(_ controller: AdaptyPaywallController,
                           didFailPurchase product: AdaptyPaywallProduct,
                           error: AdaptyError) {
        self.pushEvent(EventName.onPurchaseFailed, view: controller, data: error)
    }
    
    /// CANCEL PURCHASE PRESS
    func paywallController(_ controller: AdaptyPaywallController,
                           didCancelPurchase product: AdaptyPaywallProduct) {
        self.pushEvent(EventName.onPurchaseCancelled, view: controller, data: product)
    }

    /// RESTORE STARTED
    public func paywallControllerDidStartRestore(_ controller: AdaptyPaywallController) {
        self.pushEvent(EventName.onRestoreStarted, view: controller)
    }
    
    /// RESTORE SUCCESS
    func paywallController(_ controller: AdaptyPaywallController,
                           didFinishRestoreWith profile: AdaptyProfile) {
        self.pushEvent(EventName.onRestoreCompleted, view: controller, data: profile)
    }
    
    
    /// RESTORE FAILED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailRestoreWith error: AdaptyError) {
        self.pushEvent(EventName.onRestoreFailed, view: controller, data: error)
    }
}
