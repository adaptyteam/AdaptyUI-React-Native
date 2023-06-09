package io.adapty.react.ui

import com.adapty.models.AdaptyPaywall
import com.adapty.models.AdaptyPaywallProduct
import com.adapty.models.AdaptyViewConfiguration
import com.adapty.ui.AdaptyPaywallView

class RNAViewCache(
    val paywall: AdaptyPaywall,
    val products: List<AdaptyPaywallProduct>?,
    val view: AdaptyPaywallView,
    val config: AdaptyViewConfiguration,
) {
    val id = view.id.toString()
}
