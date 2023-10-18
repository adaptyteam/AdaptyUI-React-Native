import Foundation

enum EventName: String {
    case onCloseButtonPress = "onCloseButtonPress"
    case onProductSelected = "onProductSelected"
    case onPurchaseStarted = "onPurchaseStarted"
    case onPurchaseCancelled = "onPurchaseCancelled"
    case onPurchaseCompleted = "onPurchaseCompleted"
    case onPurchaseFailed = "onPurchaseFailed"
    case onRestoreCompleted = "onRestoreCompleted"
    case onRestoreFailed = "onRestoreFailed"
    case onRenderingFailed = "onRenderingFailed"
    case onLoadingProductsFailed = "onLoadingProductsFailed"
    case onAction = "onAction"
}

enum MethodName: String {
    case createView = "create_view"
    case presentView = "present_view"
    case dismissView = "dismiss_view"
    case notImplemented = "not_implemented"
}

struct Const {
    static let PAYWALL = "paywall"
    static let PREFETCH_PRODUCTS = "prefetch_product"
    static let VIEW_ID = "view_id"
    static let PRODUCTS_TITLES = "products_titles"
}
