package com.adapty.react.ui

enum class ParamKey(val value: String) {
  PAYWALL("paywall"),
  VIEW_ID("view_id"),
  LOCALE("locale"),
  PRODUCT_TITLES("products_titles"),
  CUSTOM_TAGS("custom_tags"),
  TIMER_INFO("timer_info"),
  PREFETCH_PRODUCTS("prefetch_products"),
}

enum class MethodName(val value: String) {
  CREATE_VIEW("create_view"),
  PRESENT_VIEW("present_view"),
  DISMISS_VIEW("dismiss_view"),
  NOT_IMPLEMENTED("not_implemented");

  companion object {
    fun fromString(value: String): MethodName {
      return values().find { it.value == value } ?: NOT_IMPLEMENTED
    }
  }
}

enum class PaywallEvent(val value: String) {
  DID_PERFORM_ACTION("paywall_view_did_perform_action"),
  DID_PERFORM_SYSTEM_BACK_ACTION("paywall_view_did_perform_system_back_action"),
  DID_SELECT_PRODUCTS("paywall_view_did_select_product"),
  DID_START_PURCHASE("paywall_view_did_start_purchase"),
  DID_CANCEL_PURCHASE("paywall_view_did_cancel_purchase"),
  DID_FINISH_PURCHASE("paywall_view_did_finish_purchase"),
  DID_FAIL_PURCHASE("paywall_view_did_fail_purchase"),
  DID_START_RESTORE("paywall_view_did_start_restore"),
  DID_FINISH_RESTORE("paywall_view_did_finish_restore"),
  DID_FAIL_RESTORE("paywall_view_did_fail_restore"),
  DID_FAIL_RENDERING("paywall_view_did_fail_rendering"),
  DID_FAIL_LOADING_PRODUCTS("paywall_view_did_fail_loading_products");

  companion object {
    fun fromString(value: String): PaywallEvent? {
      return PaywallEvent.values().find { it.value == value }
    }
  }
}

enum class EventName(val value: String) {
  ON_CLOSE_BUTTON_PRESS("onCloseButtonPress"),
  ON_ANDROID_SYSTEM_BACK("onAndroidSystemBack"),
  ON_PRODUCT_SELECTED("onProductSelected"),
  ON_PURCHASE_STARTED("onPurchaseStarted"),
  ON_PURCHASE_CANCELLED("onPurchaseCancelled"),
  ON_PURCHASE_COMPLETED("onPurchaseCompleted"),
  ON_PURCHASE_FAILED("onPurchaseFailed"),
  ON_RESTORE_STARTED("onRestoreStarted"),
  ON_RESTORE_COMPLETED("onRestoreCompleted"),
  ON_RESTORE_FAILED("onRestoreFailed"),
  ON_RENDERING_FAILED("onRenderingFailed"),
  ON_LOADING_PRODUCTS_FAILED("onLoadingProductsFailed"),
  ON_ACTION("onAction"),
  ON_CUSTOM_EVENT("onCustomEvent"),
  ON_URL_PRESS("onUrlPress");
}
