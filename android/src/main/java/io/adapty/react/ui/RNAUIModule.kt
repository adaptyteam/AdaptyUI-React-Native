package io.adapty.react.ui

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.view.View
import android.view.ViewGroup
import com.adapty.Adapty
import com.adapty.internal.crossplatform.CrossplatformHelper
import com.adapty.internal.crossplatform.CrossplatformName
import com.adapty.internal.crossplatform.MetaInfo
import com.adapty.models.AdaptyPaywall
import com.adapty.ui.AdaptyPaywallInsets
import com.adapty.ui.AdaptyUI
import com.adapty.utils.AdaptyResult
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.adapty.errors.AdaptyError
import com.adapty.models.AdaptyPaywallProduct
import com.adapty.models.AdaptyProfile
import com.adapty.ui.AdaptyPaywallView
import com.adapty.ui.listeners.AdaptyUiEventListener

fun View.onReceiveSystemBarsInsets(action: (insets: Insets) -> Unit) {
    ViewCompat.setOnApplyWindowInsetsListener(this) { _, insets ->
        val systemBarInsets = insets.getInsets(WindowInsetsCompat.Type.systemBars())

        ViewCompat.setOnApplyWindowInsetsListener(this, null)
        action(systemBarInsets)
        insets
    }
}

class RNAUIModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext), AdaptyUiEventListener {
    private var listenerCount = 0

    private val paywallControllers = mutableMapOf<String, RNAViewCache>()

    val ctx = reactContext
    private val helper = CrossplatformHelper.create(MetaInfo.from(CrossplatformName.REACT_NATIVE, "ui.1"))

    override fun getName(): String {
        return NAME
    }

    private fun cachePaywallController(controller: RNAViewCache, id: String) {
        paywallControllers[id] = controller
    }

    private fun deleteCachedPaywallController(id: String) {
        paywallControllers.remove(id)
    }

    private fun cachedPaywallController(id: String): RNAViewCache? {
        return paywallControllers[id]
    }

    @ReactMethod
    fun addListener(eventName: String?) {
        listenerCount += 1
    }

    @ReactMethod
    fun removeListeners(count: Int?) {
        listenerCount -= 1
        if (listenerCount == 0) {
            return
        }
    }

    private fun <T>sendEvent(eventName: String, view: AdaptyPaywallView, data: T?) {
        if (listenerCount == 0) {
            return
        }

        val result = RNAViewable<T>(data, view.id.toString())
        val json = helper.toJson(result)

        ctx
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, json)
    }


    override fun onCloseButtonClick(view: AdaptyPaywallView) {
        this.sendEvent(onCloseButtonPress, view, null)
    }

    override fun onLoadingProductsFailure(error: AdaptyError, view: AdaptyPaywallView): Boolean {
        this.sendEvent(onLoadingProductsFailed, view, error)
        return false
    }

    override fun onPurchaseCanceled(product: AdaptyPaywallProduct, view: AdaptyPaywallView) {
        this.sendEvent(onPurchaseCancelled, view, product)
    }

    override fun onPurchaseFailure(
        error: AdaptyError,
        product: AdaptyPaywallProduct,
        view: AdaptyPaywallView
    ) {
        this.sendEvent(onPurchaseFailed, view, error)
    }

    override fun onPurchaseSuccess(
        profile: AdaptyProfile?,
        product: AdaptyPaywallProduct,
        view: AdaptyPaywallView
    ) {
        this.sendEvent(onPurchaseCompleted, view, profile)
    }

    override fun onRenderingError(error: AdaptyError, view: AdaptyPaywallView) {
        this.sendEvent(onRenderingFailed, view, error)
    }

    override fun onRestoreFailure(error: AdaptyError, view: AdaptyPaywallView) {
        this.sendEvent(onRestoreFailed, view, error)
    }

    override fun onRestoreSuccess(profile: AdaptyProfile, view: AdaptyPaywallView) {
        this.sendEvent(onRestoreCompleted, view, profile)
    }

    override fun onUrlClicked(url: String, view: AdaptyPaywallView) {
        (view.context as? Activity)?.startActivity(
            Intent.createChooser(Intent(Intent.ACTION_VIEW, Uri.parse(url)), "") // the default behavior
        )
    }


    @ReactMethod
    fun handle(methodName: String, args: ReadableMap, promise: Promise) {
        val ctx = RNAContext(methodName, args, promise, helper, currentActivity)

        when (ctx.method) {
            CREATE_VIEW -> handleCreateView(ctx)
            PRESENT_VIEW -> handlePresentView(ctx)
            DISMISS_VIEW -> handleDismissView(ctx)
            else -> ctx.notImplemented()
        }
    }


    private fun handleCreateView(ctx: RNAContext) {
        val paywall = ctx.parseJsonArgument<AdaptyPaywall>(PAYWALL) ?: kotlin.run {
            return ctx.argNotFound(PAYWALL)
        }

        Adapty.getViewConfiguration(paywall) { result ->
            when (result) {
                is AdaptyResult.Error -> ctx.err(result.error)
                is AdaptyResult.Success -> {
                    val config = result.value

                    ctx.activity?.let { activity ->
                        val view = AdaptyUI.getPaywallView(
                            activity,
                            paywall,
                            null,
                            config,
                            AdaptyPaywallInsets.NONE,
                            this
                        )

                        val cache = RNAViewCache(paywall, null, view, config)

                        this.cachePaywallController(cache, cache.id)
                        return@getViewConfiguration ctx.success(cache.id)
                    }
                }
            }

        }
    }

    private fun handlePresentView(ctx: RNAContext) {
        val id = ctx.args.getString(VIEW_ID) ?: kotlin.run {
            return ctx.argNotFound(VIEW_ID)
        }

        val cache = this.cachedPaywallController(id) ?: kotlin.run {
            return ctx.argNotFound(VIEW_ID)
        }


        val parent = currentActivity?.findViewById<ViewGroup>(android.R.id.content) ?: kotlin.run {
            return ctx.argNotFound("parent")
        }

        currentActivity?.runOnUiThread {
            parent.addView(cache.view)
            cache.view.showPaywall(cache.paywall, cache.products, cache.config, AdaptyPaywallInsets.NONE)
        }

        return ctx.success(null)
    }


    // cache.view.onReceiveSystemBarsInsets { insets ->
    // val paywallInsets = AdaptyPaywallInsets.of(insets.top, insets.bottom)
    // cache.view.showPaywall(cache.paywall, cache.products, cache.config, paywallInsets)
    // }

    private fun handleDismissView(ctx: RNAContext) {
        val id = ctx.args.getString(VIEW_ID) ?: kotlin.run {
            return ctx.argNotFound(VIEW_ID)
        }

        val cache = this.cachedPaywallController(id) ?: kotlin.run {
            return ctx.argNotFound(VIEW_ID)
        }


        currentActivity?.runOnUiThread {
            cache.view.visibility = View.GONE
            this.deleteCachedPaywallController(cache.id)
        }

        return ctx.success(null)
    }

    companion object {
        const val NAME = "RNAUICallHandler"

        // methods
        const val PRESENT_VIEW = "present_view"
        const val CREATE_VIEW = "create_view"
        const val DISMISS_VIEW = "dismiss_view"

        // params
        const val PAYWALL = "paywall"
        const val VIEW_ID = "view_id"

        // Events
        const val onCloseButtonPress = "onCloseButtonPress"
        const val onProductSelected = "onProductSelected"
        const val onPurchaseStarted = "onPurchaseStarted"
        const val onPurchaseCancelled = "onPurchaseCancelled"
        const val onPurchaseCompleted = "onPurchaseCompleted"
        const val onPurchaseFailed = "onPurchaseFailed"
        const val onRestoreCompleted = "onRestoreCompleted"
        const val onRestoreFailed = "onRestoreFailed"
            const val onRenderingFailed = "onRenderingFailed"
        const val onLoadingProductsFailed = "onLoadingProductsFailed"

    }
}
