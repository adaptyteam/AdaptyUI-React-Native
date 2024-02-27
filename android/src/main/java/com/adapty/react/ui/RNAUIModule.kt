package com.adapty.react.ui

import com.adapty.errors.AdaptyError
import com.adapty.internal.crossplatform.ui.AdaptyUiView
import com.adapty.internal.crossplatform.ui.CrossplatformUiHelper
import com.adapty.models.AdaptyPaywall
import com.adapty.models.AdaptyPaywallProduct
import com.adapty.models.AdaptyProfile
import com.adapty.ui.AdaptyUI
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.adapty.react.ui.PaywallEvent.*

class RNAUIModule(private val ctx: ReactApplicationContext) : ReactContextBaseJavaModule(ctx) {
  private val helper = CrossplatformUiHelper.shared
  private val subscribedEventsCount: HashMap<String, Int> = HashMap()
  private var listenerCount = 0


  override fun getName(): String {
    return "RNAUICallHandler"
  }

  override fun getConstants(): MutableMap<String, Any>? {
    // Name of the function that routes all incoming calls
    return hashMapOf("HANDLER" to "handle")
  }

  @ReactMethod
  fun addListener(eventName: String?) {
    eventName?.let { event ->
      val count = subscribedEventsCount[event] ?: 0
      subscribedEventsCount[event] = count + 1
    }
    listenerCount += 1

    if (listenerCount == 1) {
      listenPaywallEvents()
    }
  }

  @ReactMethod
  fun removeListeners(count: Int?) {
    subscribedEventsCount.clear()
  }

  private inline fun <reified T : Any> sendEvent(
    eventName: EventName,
    params: T?,
    view: String
  ) {
    if (listenerCount == 0) {
      return
    }

    val result = params?.let {   AdaptyBridgeResult(
      params,
      T::class.simpleName ?: "Any",
      view
    ) } ?: AdaptyBridgeResult(NullEncodable(), "null", view)

    val receiver = ctx.getJSModule(
      DeviceEventManagerModule.RCTDeviceEventEmitter::class.java
    )

    receiver.emit(
      eventName.value,
      result.let(helper.serialization::toJson)
    )
  }

  private fun listenPaywallEvents() {
    helper.uiEventsObserver = { event ->
      val view = event.data["view"] as AdaptyUiView

      when (PaywallEvent.fromString(event.name)) {
        DID_SELECT_PRODUCTS -> {
          val product = event.data["product"] as AdaptyPaywallProduct
          sendEvent(EventName.ON_PRODUCT_SELECTED, product, view.id)
        }
        DID_START_PURCHASE -> {
          val product = event.data["product"] as AdaptyPaywallProduct
          sendEvent(EventName.ON_PURCHASE_STARTED, product, view.id)
        }
        DID_CANCEL_PURCHASE -> {
          val product = event.data["product"] as AdaptyPaywallProduct
          sendEvent(EventName.ON_PURCHASE_CANCELLED, product, view.id)
        }
        DID_FINISH_PURCHASE -> {
          val profile = event.data["profile"] as AdaptyProfile
          sendEvent(EventName.ON_PURCHASE_COMPLETED, profile, view.id)
        }
        DID_FAIL_PURCHASE -> {
          val error = event.data["error"] as AdaptyError
          sendEvent(EventName.ON_PURCHASE_FAILED, error, view.id)
        }
        DID_START_RESTORE -> {
          sendEvent(EventName.ON_RESTORE_STARTED, null, view.id)
        }
        DID_FINISH_RESTORE -> {
          val profile = event.data["profile"] as AdaptyProfile
          sendEvent(EventName.ON_RESTORE_COMPLETED, profile, view.id)
        }
        DID_FAIL_RESTORE -> {
          val error = event.data["error"] as AdaptyError
          sendEvent(EventName.ON_RESTORE_FAILED, error, view.id)
        }
        DID_FAIL_RENDERING -> {
          val error = event.data["error"] as AdaptyError
          sendEvent(EventName.ON_RENDERING_FAILED, error, view.id)
        }
        DID_FAIL_LOADING_PRODUCTS -> {
          val error = event.data["error"] as AdaptyError
          sendEvent(EventName.ON_LOADING_PRODUCTS_FAILED, error, view.id)
        }
        DID_PERFORM_ACTION -> {

          when (val action = event.data["action"] as AdaptyUI.Action) {
            is AdaptyUI.Action.Close -> sendEvent(EventName.ON_CLOSE_BUTTON_PRESS,null, view.id)
            is AdaptyUI.Action.Custom -> {
              sendEvent(EventName.ON_CUSTOM_EVENT, action.customId, view.id)
            }
            is AdaptyUI.Action.OpenUrl -> {
              sendEvent(EventName.ON_URL_PRESS, action.url, view.id)
            }
          }
        }
        DID_PERFORM_SYSTEM_BACK_ACTION -> sendEvent(EventName.ON_ANDROID_SYSTEM_BACK,null, view.id)

        null -> {}
      }
    }
  }

  @ReactMethod
  fun handle(methodName: String, args: ReadableMap, promise: Promise) {
    helper.activity = currentActivity
    val ctx = AdaptyContext(methodName, args, promise)

    try {
      when (ctx.methodName) {
        MethodName.CREATE_VIEW -> handleCreateView(ctx)
        MethodName.PRESENT_VIEW -> handlePresentView(ctx)
        MethodName.DISMISS_VIEW -> handleDismissView(ctx)

        else -> throw BridgeError.MethodNotImplemented
      }
    } catch (error: Error) {
      ctx.bridgeError(error, "")
    }
  }

  private fun handleCreateView(ctx: AdaptyContext) {
    val paywall: AdaptyPaywall = ctx.params.getDecodedValue(
      ParamKey.PAYWALL,
    )
    val locale: String? = ctx.params.getOptionalValue(ParamKey.LOCALE)
    val preloadProducts: Boolean = ctx.params.getOptionalValue(ParamKey.PREFETCH_PRODUCTS) ?: false
    val personalizedOffers: HashMap<String, Boolean>? = ctx.params.getOptionalValue(ParamKey.PRODUCT_TITLES)
    val customTags: HashMap<String, String>? = ctx.params.getDecodedOptionalValue(ParamKey.CUSTOM_TAGS)


    helper.handleCreateView(
      paywall,
      locale ?: "en",
      preloadProducts,
      personalizedOffers,
      customTags,
      { jsonView ->
        ctx.resolve(jsonView.id, "") },
      { error -> ctx.forwardError(error, "") }
    )
  }

  private fun handlePresentView(ctx: AdaptyContext) {
    val id: String = ctx.params.getRequiredValue(ParamKey.VIEW_ID)

    helper.handlePresentView(
      id,
      { ctx.resovle(id) },
      { error -> ctx.uiError(error, "") },
    )
  }

  private fun handleDismissView(ctx: AdaptyContext) {
    val id: String = ctx.params.getRequiredValue(ParamKey.VIEW_ID)

    helper.handleDismissView(
      id,
      { ctx.resovle(id) },
      { error -> ctx.uiError(error, id) },
    )
  }
}
