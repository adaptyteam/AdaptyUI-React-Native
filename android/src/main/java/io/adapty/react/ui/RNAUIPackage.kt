package io.adapty.react.ui

import com.adapty.errors.AdaptyError
import com.adapty.internal.crossplatform.CrossplatformHelper
import com.adapty.internal.crossplatform.CrossplatformName
import com.adapty.internal.crossplatform.MetaInfo
import com.adapty.models.AdaptyPaywallProduct
import com.adapty.models.AdaptyProfile
import com.adapty.ui.AdaptyPaywallView
import com.adapty.ui.listeners.AdaptyUiDefaultEventListener
import com.adapty.ui.listeners.AdaptyUiEventListener
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.uimanager.ViewManager


class RNAUIPackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    var listenerCount = 0


    val listener = object : AdaptyUiDefaultEventListener() {
      private val helper =
        CrossplatformHelper.create(MetaInfo.from(CrossplatformName.REACT_NATIVE, "ui.1"))

      private fun <T> sendEvent(eventName: String, view: AdaptyPaywallView, data: T?) {
        if (listenerCount == 0) {
          return
        }

        val result = RNAViewable<T>(data, view.id.toString())
        val json = helper.toJson(result)

        reactContext
          .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
          .emit(eventName, json)
      }


      override fun onPurchaseCanceled(
        product: AdaptyPaywallProduct,
        view: AdaptyPaywallView
      ) {
        this.sendEvent(RNAUIModule.onPurchaseCancelled, view, product)
      }

      override fun onPurchaseFailure(
        error: AdaptyError,
        product: AdaptyPaywallProduct,
        view: AdaptyPaywallView
      ) {
        this.sendEvent(RNAUIModule.onPurchaseFailed, view, error)
      }

      override fun onPurchaseSuccess(
        profile: AdaptyProfile?,
        product: AdaptyPaywallProduct,
        view: AdaptyPaywallView
      ) {
        this.sendEvent(RNAUIModule.onPurchaseCompleted, view, profile)
      }

      override fun onRenderingError(error: AdaptyError, view: AdaptyPaywallView) {
        this.sendEvent(RNAUIModule.onRenderingFailed, view, error)
      }

      override fun onRestoreFailure(error: AdaptyError, view: AdaptyPaywallView) {
        this.sendEvent(RNAUIModule.onRestoreFailed, view, error)
      }

      override fun onRestoreSuccess(profile: AdaptyProfile, view: AdaptyPaywallView) {
        this.sendEvent(RNAUIModule.onRestoreCompleted, view, profile)
      }
    }

    return listOf(
      RNAUIModule(
        reactContext,
        listener
      ) { newCount ->
        listenerCount = newCount
      }
    )
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }
}
