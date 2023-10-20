package io.adapty.react.ui

import com.adapty.internal.crossplatform.ui.CrossplatformUiHelper
import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager


class RNAUIPackage : ReactPackage {
  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }

  override fun createNativeModules(
    reactContext: ReactApplicationContext
  ): List<NativeModule> {
    CrossplatformUiHelper.init(reactContext)
    CrossplatformUiHelper.shared.activity = reactContext.currentActivity

    return listOf(RNAUIModule(reactContext))
  }
}
