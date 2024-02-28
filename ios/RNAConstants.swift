import Foundation

enum EventName: String {
    case onCloseButtonPress = "onCloseButtonPress"
    case onProductSelected = "onProductSelected"
    case onPurchaseStarted = "onPurchaseStarted"
    case onPurchaseCancelled = "onPurchaseCancelled"
    case onPurchaseCompleted = "onPurchaseCompleted"
    case onPurchaseFailed = "onPurchaseFailed"
    case onRestoreStarted = "onRestoreStarted"
    case onRestoreCompleted = "onRestoreCompleted"
    case onRestoreFailed = "onRestoreFailed"
    case onRenderingFailed = "onRenderingFailed"
    case onLoadingProductsFailed = "onLoadingProductsFailed"
    case onAction = "onAction"
    case onCustomEvent = "onCustomEvent"
    case onUrlPress = "onUrlPress"
    case onAndroidSystemBack = "onAndroidSystemBack"
}

enum MethodName: String {
    case createView = "create_view"
    case presentView = "present_view"
    case dismissView = "dismiss_view"
    case notImplemented = "not_implemented"
}
