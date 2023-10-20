@file:Suppress("SpellCheckingInspection")

package io.adapty.react.ui

import android.app.Activity
import com.adapty.errors.AdaptyError
import com.adapty.internal.crossplatform.CrossplatformHelper
import com.adapty.internal.crossplatform.ui.AdaptyUiBridgeError
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableMap

data class AdaptyBridgeResult<T : Any>(
  val data: T?,
  val type: String,
  val view: String
)

class NullEncodable

class AdaptyContext(
  methodString: String,
  args: ReadableMap,
  private val __promise: Promise,
) {
  val methodName = MethodName.fromString(methodString)
  val params = ParamMap(args)

  fun <T : Any> resolve(result: AdaptyBridgeResult<T>) {
    try {
      val jsonStr = result.let(CrossplatformHelper.shared::toJson)
      return this.__promise.resolve(jsonStr)
    } catch (e: Exception) {
      bridgeError(e, result.view)
    }
  }

  inline fun <reified T : Any> resolve(data: T, viewId: String) {
    val typeName = if (data is List<*>) {
      val elementType = data.firstOrNull()?.javaClass?.simpleName ?: "UnknownType"
      "Array<$elementType>"
    } else {
      T::class.simpleName ?: "UnknownType"
    }
    val result = AdaptyBridgeResult(data, typeName, viewId)
    return resolve(result)
  }

  fun resovle(viewId: String) {
    val result = AdaptyBridgeResult(
      data = NullEncodable(), type = "null", viewId
    )

    return this.resolve(result)
  }

  private fun <T : Any> reject(result: AdaptyBridgeResult<T>) {
    try {
      val jsonStr = result.let(CrossplatformHelper.shared::toJson)

      return this.__promise.reject(
        "adapty_rn_bridge_error", jsonStr
      )
    } catch (error: Exception) {
      bridgeError(error, result.view)
    }
  }

  fun forwardError(error: AdaptyError, viewId: String) {
    val result = AdaptyBridgeResult(
      data = error, type = AdaptyError::class.java.simpleName, viewId,
    )

    return reject(result)
  }

  fun bridgeError(error: Throwable, viewId: String) {
    if (error is BridgeError) {
      val result = AdaptyBridgeResult(
        data = error.toJson(), type = BridgeError::class.java.simpleName, viewId,
      )

      return reject(result)
    }

    val unknownBridgeError = BridgeError.UnexpectedError(error)
    val result = AdaptyBridgeResult(
      data = unknownBridgeError, type = BridgeError::class.java.simpleName, viewId
    )
    return reject(result)
  }

  fun uiError(error: AdaptyUiBridgeError, viewId: String) {
      val result = AdaptyBridgeResult(
        data = BridgeError.UiError(error).toJson(), type = BridgeError::class.java.simpleName, viewId,
      )

      return reject(result)
  }
}
