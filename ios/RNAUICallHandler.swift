import Foundation
import Adapty
import AdaptyUI
import react_native_adapty

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
            EventName.onRestoreCompleted.rawValue,
            EventName.onRestoreFailed.rawValue,
            EventName.onRenderingFailed.rawValue,
            EventName.onLoadingProductsFailed.rawValue,
        ]
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
        
        // could not infer generic type?
        let respData = Viewable.init(payload: nil as AdaptyProfile?, view: view)
        guard let bytes = try? AdaptyContext.jsonEncoder.encode(respData),
              let dataStr = String(data: bytes, encoding: .utf8)
        else {
            // TODO: Should not happen
            return self.pushEvent(event, view: view)
        }
        
        self.sendEvent(withName: event.rawValue, body: dataStr)
    }
    
    /// Sends event to JS layer if client has listeners
    private func pushEvent<T: Encodable>(_ event: EventName, view: AdaptyPaywallController, data: T) {
        if !hasListeners {
            return
        }
        
        let respData = Viewable.init(payload: data, view: view)
        
        guard let bytes = try? AdaptyContext.jsonEncoder.encode(respData),
              let dataStr = String(data: bytes, encoding: .utf8)
        else {
            // TODO: Should not happen
            return self.pushEvent(event, view: view)
        }
        
        self.sendEvent(withName: event.rawValue, body: dataStr)
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
    
    private func getConfigurationAndCreateView(ctx: AdaptyContext,
                                               paywall: AdaptyPaywall,
                                               preloadProducts: Bool,
                                               productsTitlesResolver: ((AdaptyProduct) -> String)?
    ) {
        AdaptyUI.getViewConfiguration(forPaywall: paywall) { [weak self] result in
            switch result {
            case let .failure(error):
                return ctx.err(error)
                
            case let .success(config):
                let vc = AdaptyUI.paywallController(for: paywall,
                                                    products: nil,
                                                    viewConfiguration: config,
                                                    delegate: self
                                                    // productsTitlesResolver: productsTitlesResolver,
                )
                
                guard let uuid = UUID(uuidString: vc.toView().id) else {
                    return ctx.notImplemented()
                }
                
                self?.cachePaywallController(vc, id: uuid)
                
                print("ADADJKL",uuid.uuidString)
                return ctx.resolver(uuid.uuidString)
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
        let ctx = AdaptyContext(args: args, resolver: resolver, rejecter: rejecter)
        
        switch MethodName(rawValue: method as String) ?? .notImplemented {
        case .createView: handleCreateView(ctx)
        case .presentView: handlePresentView(ctx)
        case .dismissView: handleDismissView(ctx)
        default: handleNotImplemented(ctx)
        }
    }
    
    private func handleCreateView(_ ctx: AdaptyContext) {
        guard let paywallString = ctx.args[Const.PAYWALL] as? String,
              let paywallData = paywallString.data(using: .utf8),
              let paywall = try? AdaptyContext.jsonDecoder.decode(AdaptyPaywall.self, from: paywallData) else {
            return ctx.argNotFound(name: Const.PAYWALL)
        }
        
        let preloadProducts = ctx.args[Const.PREFETCH_PRODUCTS] as? Bool ?? false
        let productsTitles = ctx.args[Const.PRODUCTS_TITLES] as? [String: String]
        
        getConfigurationAndCreateView(
            ctx: ctx,
            paywall: paywall,
            preloadProducts: preloadProducts,
            productsTitlesResolver: { productsTitles?[$0.vendorProductId] ?? $0.localizedTitle }
        )
    }
    
    private func handlePresentView(_ ctx: AdaptyContext) {
        guard let id = ctx.args[Const.VIEW_ID] as? String else {
            return ctx.argNotFound(name: Const.VIEW_ID)
        }
        
        guard let vc = cachedPaywallController(id) else {
            //            let error = AdaptyError(AdaptyUIFlutterError.viewNotFound(id))
            //            flutterCall.callAdaptyError(flutterResult, error: error)
            return ctx.notImplemented()
        }
        
        
        DispatchQueue.main.async {
            vc.modalPresentationStyle = .overFullScreen
            
            guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
                //            let error = AdaptyError(AdaptyUIFlutterError.viewPresentationError(id))
                //            flutterCall.callAdaptyError(flutterResult, error: error)
                return ctx.notImplemented()
            }
            
            guard !rootVC.isOrContainsAdaptyController else {
                //            let error = AdaptyError(AdaptyUIFlutterError.viewAlreadyPresented(id))
                //            flutterCall.callAdaptyError(flutterResult, error: error)
                return ctx.notImplemented()
            }
            
            rootVC.present(vc, animated: true) {
                ctx.resolve()
            }
        }
    }
    
    private func handleDismissView(_ ctx: AdaptyContext) {
        guard let id = ctx.args[Const.VIEW_ID] as? String else {
            return ctx.argNotFound(name: Const.VIEW_ID)
        }
        
        guard let vc = cachedPaywallController(id) else {
            //            let error = AdaptyError(AdaptyUIFlutterError.viewNotFound(id))
            //            flutterCall.callAdaptyError(flutterResult, error: error)
            return ctx.argNotFound(name: "a")
        }
        
        DispatchQueue.main.async {
            vc.dismiss(animated: true) { [weak self] in
                self?.deleteCachedPaywallController(id)
                
                return ctx.resolve()
            }
        }
    }
    
    private func handleNotImplemented(_ ctx: AdaptyContext) {
        return ctx.notImplemented()
    }
    
    // MARK: - Event Handlers
    
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didStartPurchase product: AdaptyPaywallProduct) {
        self.pushEvent(EventName.onPurchaseStarted, view: controller, data: product)
    }
    
    
    /// CLOSE BUTTON PRESS
    public func paywallControllerDidPressCloseButton(_ controller: AdaptyPaywallController) {
        self.pushEvent(EventName.onCloseButtonPress, view: controller)
    }
    
    /// CANCEL PURCHASE PRESS
    public func paywallControllerDidCancelPurchase(_ controller: AdaptyPaywallController) {
        self.pushEvent(EventName.onPurchaseCancelled, view: controller)
    }
    
    /// PURCHASE SUCCESS
    public func paywallController(_ controller: AdaptyPaywallController, didFinishPurchaseWith profile: AdaptyProfile) {
        let data = Viewable.init(payload: profile, view: controller)
        
        self.pushEvent(EventName.onPurchaseCompleted, view: controller, data: data)
    }
    
    /// PURCHASE FAILED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailPurchaseWith error: AdaptyError) {
        let data = Viewable.init(payload: error, view: controller)
        
        self.pushEvent(EventName.onPurchaseFailed, view: controller, data: data)
    }
    
    /// RESTORE SUCCESS
    func paywallController(_ controller: AdaptyPaywallController, didFinishRestoreWith profile: AdaptyProfile) {
        let data = Viewable.init(payload: profile, view: controller)
        
        self.pushEvent(EventName.onRestoreCompleted, view: controller, data: data)
    }
    
    /// RESTORE FAILED
    public func paywallController(_ controller: AdaptyPaywallController, didFailRestoreWith error: AdaptyError) {
        let data = Viewable.init(payload: error, view: controller)
        
        self.pushEvent(EventName.onRestoreFailed, view: controller, data: data)
    }
    
    /// LOAD PRODUCTS FAILED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailLoadingProductsWith policy: AdaptyProductsFetchPolicy,
                                  error: AdaptyError) -> Bool {
        let data = Viewable.init(payload: error, view: controller)
        
        self.pushEvent(EventName.onLoadingProductsFailed, view: controller, data: data)
        return policy == .default
    }
    
    /// RENDERING FAILED
    public func paywallController(_ controller: AdaptyPaywallController,
                                  didFailRenderingWith error: AdaptyError) {
        let data = Viewable.init(payload: error, view: controller)
        
        self.pushEvent(EventName.onRenderingFailed, view: controller, data: data)
    }
}
