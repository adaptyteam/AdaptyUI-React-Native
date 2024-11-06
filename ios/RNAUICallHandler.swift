import Foundation
import Adapty
import AdaptyUI
import react_native_adapty_sdk

@available(iOS 15.0, *)
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
    
    private var paywallControllers = [UUID: Any]()
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
    @available(iOS 15.0, *)
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
    @available(iOS 15.0, *)
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
    
    @available(iOS 15.0, *)
    private func cachePaywallController(_ controller: AdaptyPaywallController, id: UUID) {
        paywallControllers[id] = controller
    }
    
    @available(iOS 15.0, *)
    private func deleteCachedPaywallController(_ id: String) {
        guard let uuid = UUID(uuidString: id) else { return }
        paywallControllers.removeValue(forKey: uuid)
    }
    
    @available(iOS 15.0, *)
    private func cachedPaywallController(_ id: String) -> AdaptyPaywallController? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return paywallControllers[uuid] as? AdaptyPaywallController
    }
    
    @available(iOS 15.0, *)
    private func getConfigurationAndCreateView(
        ctx: AdaptyContext,
        paywall: AdaptyPaywall,
        preloadProducts: Bool,
        customTags: [String: String]?,
        timerInfo: [String: String]?
    ) {
        AdaptyUI.getViewConfiguration(forPaywall: paywall) { result in
            switch result {
            case let .failure(error):
                return ctx.forwardError(error)
                
            case let .success(config):
                let vc: AdaptyPaywallController
                
                do {
                    vc = try AdaptyUI.paywallController(
                        for: paywall,
                        products: nil,
                        viewConfiguration: config,
                        delegate: self,
                        tagResolver: customTags,
                        timerResolver: timerInfo
                    )
                } catch {
                    return ctx.bridgeError(error)
                }
                
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
        guard #available(iOS 15.0, *) else {
            throw BridgeError.unsupportedIosVersion
        }
        
        let paywallStr: String = try ctx.params.getRequiredValue(for: .paywall)
        let preloadProducts: Bool? = ctx.params.getOptionalValue(for: .prefetch_products)
        let customTags: [String: String]? = try ctx.params.getDecodedOptionalValue(for: .custom_tags, jsonDecoder: AdaptyContext.jsonDecoder)
        let timerInfo: [String: String]? = try ctx.params.getDecodedOptionalValue(for: .timer_info, jsonDecoder: AdaptyContext.jsonDecoder)
        
        guard let paywallData = paywallStr.data(using: .utf8),
              let paywall = try? AdaptyContext.jsonDecoder.decode(AdaptyPaywall.self, from: paywallData)
        else {
            throw BridgeError.typeMismatch(name: .paywall, type: "String")
        }
        
        getConfigurationAndCreateView(
            ctx: ctx,
            paywall: paywall,
            preloadProducts: preloadProducts ?? false,
            customTags: customTags,
            timerInfo: timerInfo
        )
    }
    
    private func handlePresentView(_ ctx: AdaptyContext) throws {
        guard #available(iOS 15.0, *) else {
            throw BridgeError.unsupportedIosVersion
        }
        
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

            var currentVC = rootVC
            while currentVC.presentedViewController != nil {
                currentVC = currentVC.presentedViewController!
            }

            currentVC.present(vc, animated: true) {
                ctx.resolve()
            }
        }
    }
    
    private func handleDismissView(_ ctx: AdaptyContext) throws {
        guard #available(iOS 15.0, *) else {
            throw BridgeError.unsupportedIosVersion
        }
        
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
    @available(iOS 15.0, *)
    func paywallController(_ controller: AdaptyPaywallController, didPerform action: AdaptyUI.Action) {
        self.pushEvent(EventName.onAction, view: controller)
        switch action {
        case .close:
            self.pushEvent(EventName.onCloseButtonPress, view: controller)
            break
        case let .openURL(url):
            self.pushEvent(.onUrlPress, view: controller, data: url.absoluteString)
            break
        case let .custom(id):
            self.pushEvent(.onCustomEvent, view: controller, data: id)
            break
            
        }
    }
    
    
    /// PRODUCT SELECTED
    @available(iOS 15.0, *)
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didSelectProduct product: AdaptyPaywallProduct) {
        self.pushEvent(EventName.onProductSelected, view: controller, data: product)
    }
    
    /// PURCHASE STARTED
    @available(iOS 15.0, *)
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didStartPurchase product: AdaptyPaywallProduct) {
        self.pushEvent(EventName.onPurchaseStarted, view: controller, data: product)
    }
    
    /// PURCHASE SUCCESS
    @available(iOS 15.0, *)
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFinishPurchase product: AdaptyPaywallProduct,
                                  purchasedInfo: AdaptyPurchasedInfo) {
        self.pushEvent(EventName.onPurchaseCompleted, view: controller, data: purchasedInfo.profile)
    }
    
    /// RENDERING FAILED
    @available(iOS 15.0, *)
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailRenderingWith error: AdaptyError) {
        self.pushEvent(EventName.onRenderingFailed, view: controller, data: error)
    }
    
    /// LOAD PRODUCTS FAILED
    @available(iOS 15.0, *)
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailLoadingProductsWith error: AdaptyError) -> Bool {
        self.pushEvent(EventName.onLoadingProductsFailed, view: controller, data: error)
        
        return true
    }
    
    /// PURCHASE FAILED
    @available(iOS 15.0, *)
    func paywallController(_ controller: AdaptyPaywallController,
                           didFailPurchase product: AdaptyPaywallProduct,
                           error: AdaptyError) {
        self.pushEvent(EventName.onPurchaseFailed, view: controller, data: error)
    }
    
    /// CANCEL PURCHASE PRESS
    @available(iOS 15.0, *)
    func paywallController(_ controller: AdaptyPaywallController,
                           didCancelPurchase product: AdaptyPaywallProduct) {
        self.pushEvent(EventName.onPurchaseCancelled, view: controller, data: product)
    }

    /// RESTORE STARTED
    @available(iOS 15.0, *)
    public func paywallControllerDidStartRestore(_ controller: AdaptyPaywallController) {
        self.pushEvent(EventName.onRestoreStarted, view: controller)
    }
    
    /// RESTORE SUCCESS
    @available(iOS 15.0, *)
    func paywallController(_ controller: AdaptyPaywallController,
                           didFinishRestoreWith profile: AdaptyProfile) {
        self.pushEvent(EventName.onRestoreCompleted, view: controller, data: profile)
    }
    
    
    /// RESTORE FAILED
    @available(iOS 15.0, *)
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailRestoreWith error: AdaptyError) {
        self.pushEvent(EventName.onRestoreFailed, view: controller, data: error)
    }
}

extension Dictionary<String, String>: AdaptyTimerResolver {
    public func timerEndAtDate(for timerId: String) -> Date {
        if let dateStr = self[timerId], let date = endTimeStrToDate(dateStr: dateStr) {
            return date
        }
        return Date(timeIntervalSinceNow: 3600.0)
    }

    private func endTimeStrToDate(dateStr: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.date(from: dateStr)
    }
}
