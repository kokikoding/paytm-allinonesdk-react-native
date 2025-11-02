package com.arnpaytmallinone

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.text.TextUtils
import android.util.Log
import android.widget.Toast
import com.facebook.react.bridge.*
import com.paytm.pgsdk.PaytmOrder
import com.paytm.pgsdk.PaytmPaymentTransactionCallback
import com.paytm.pgsdk.TransactionManager
import org.json.JSONException
import org.json.JSONObject
import java.util.*

class AllInOneSDKManagerModule(private val reactCtx: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactCtx), ActivityEventListener {

  private val REQ_CODE = 410
  private val ERROR_CODE = "0"
  private var promise: Promise? = null

  init {
    reactCtx.addActivityEventListener(this)
  }

  override fun getName(): String = "AllInOneSDKManager"

  @ReactMethod
  fun startTransaction(
    orderId: String?,
    mid: String?,
    txnToken: String?,
    amount: String?,
    callbackUrl: String?,
    isStaging: Boolean,
    restrictAppInvoke: Boolean,
    urlScheme: String?,
    call: Promise
  ) {
    if (TextUtils.isEmpty(orderId) || TextUtils.isEmpty(mid)
      || TextUtils.isEmpty(txnToken) || TextUtils.isEmpty(amount)
    ) {
      val msg = if (TextUtils.isEmpty(txnToken)) "txnToken error" else "Please enter all fields"
      setResult(msg, call)
      Toast.makeText(reactCtx, msg, Toast.LENGTH_LONG).show()
      return
    }

    promise = call
    var callbackUri = callbackUrl ?: ""
    val host = if (isStaging) "https://securegw-stage.paytm.in/" else "https://securegw.paytm.in/"
    if (callbackUri.trim().isEmpty()) {
      callbackUri = host + "theia/paytmCallback?ORDER_ID=" + orderId
    }

    val paytmOrder = PaytmOrder(orderId, mid, txnToken, amount, callbackUri)
    val transactionManager = TransactionManager(paytmOrder, object : PaytmPaymentTransactionCallback {
      override fun onTransactionResponse(bundle: Bundle?) {
        val resp = bundle ?: Bundle.EMPTY
        if (resp.getString("STATUS") == "TXN_SUCCESS") {
          setResult(getData(resp), call)
        } else {
          setResult(resp.getString("RESPMSG") ?: "Transaction failed", call)
        }
      }

      override fun networkNotAvailable() = setResult("networkNotAvailable", call)
      override fun onErrorProceed(s: String?) = setResult(s ?: "onErrorProceed", call)
      override fun clientAuthenticationFailed(s: String?) = setResult(s ?: "clientAuthenticationFailed", call)
      override fun someUIErrorOccurred(s: String?) = setResult(s ?: "someUIErrorOccurred", call)
      override fun onErrorLoadingWebPage(code: Int, msg: String?, url: String?) =
        setResult("${msg ?: "onErrorLoadingWebPage"}, url: $url", call)
      override fun onBackPressedCancelTransaction() = setResult("onBackPressedCancelTransaction", call)
      override fun onTransactionCancel(s: String?, bundle: Bundle?) {
        val data = bundle ?: Bundle()
        if (data.getString("STATUS") == "TXN_SUCCESS") {
          setResult(getData(data), call)
        } else {
          setResult(data.getString("RESPMSG") ?: s ?: "Transaction cancelled", call)
        }
      }
    })

    transactionManager.callingBridge = "ReactNative"
    if (restrictAppInvoke) transactionManager.setAppInvokeEnabled(false)
    transactionManager.setShowPaymentUrl(host + "theia/api/v1/showPaymentPage")

    val activity: Activity? = reactCtx.currentActivity
    if (activity == null) {
      setResult("No active Activity found", call)
      return
    }

    try {
      transactionManager.startTransaction(activity, REQ_CODE)
    } catch (e: Exception) {
      setResult("Failed to start transaction: ${e.message}", call)
    }
  }

  // Proper ActivityEventListener methods for RN 0.71+
  override fun onActivityResult(
    activity: Activity,
    requestCode: Int,
    resultCode: Int,
    data: Intent?
  ) {
    if (requestCode != REQ_CODE) return

    if (data == null) {
      setResult("unknown error", promise)
      return
    }

    val message = data.getStringExtra("nativeSdkForMerchantMessage") ?: ""
    val response = data.getStringExtra("response") ?: ""
    handleResponse(response, message)
  }

  override fun onNewIntent(intent: Intent) {
    // no-op
  }

  private fun handleResponse(response: String, errorMsg: String) {
    when {
      response.isNotEmpty() -> {
        try {
          val resultJson = JSONObject(response)
          if (resultJson.optString("STATUS") == "TXN_SUCCESS") {
            setResult(getData(resultJson), promise)
          } else {
            setResult(resultJson.optString("RESPMSG", "Transaction failed"), promise)
          }
        } catch (e: Exception) {
          setResult("Response parse error: ${e.message}", promise)
        }
      }
      errorMsg.isNotEmpty() -> setResult(errorMsg, promise)
      else -> setResult("unexpected error", promise)
    }
  }

  private fun setResult(message: String, call: Promise?) {
    call?.reject(ERROR_CODE, message)
  }

  private fun setResult(data: WritableMap, call: Promise?) {
    try {
      call?.resolve(data)
    } catch (e: JSONException) {
      call?.reject(ERROR_CODE, e.message)
    }
  }

  private fun getData(bundle: Bundle): WritableMap {
    val data = Arguments.createMap()
    for (key in bundle.keySet()) {
      data.putString(key, bundle.getString(key, ""))
    }
    return data
  }

  private fun getData(json: JSONObject): WritableMap {
    val data = Arguments.createMap()
    val keys = json.keys()
    while (keys.hasNext()) {
      val key = keys.next()
      data.putString(key, json.optString(key))
    }
    return data
  }
}