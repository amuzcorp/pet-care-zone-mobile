package com.lge.petcarezone.module.network

import android.content.Context
import android.util.Log
import androidx.lifecycle.MutableLiveData
import com.connectsdk.device.ConnectableDevice
import com.connectsdk.discovery.DiscoveryManager
import com.connectsdk.discovery.DiscoveryManagerListener
import com.connectsdk.service.WebOSTVService
import com.connectsdk.service.capability.listeners.ResponseListener
import com.connectsdk.service.command.ServiceCommand
import com.connectsdk.service.command.ServiceCommandError
import com.lge.petcarezone.module.activities.IActivityController
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class DiscoveryListener(private val controller: IActivityController) : DiscoveryManagerListener {

    private var channel: MethodChannel? = null
    private var mDiscoveryManager: DiscoveryManager? = null
    private var mDeviceList: MutableLiveData<List<ConnectableDevice>> = MutableLiveData()
    private val isScan: MutableLiveData<Boolean> = MutableLiveData()
    private var webOSTVService: WebOSTVService? = null
    private fun jsonDeviceInfoToMap(jsonString: String): Map<String, Any> {
        val jsonObject = JSONObject(jsonString)
        return jsonToMap(jsonObject)
    }

    private fun jsonToMap(jsonObject: JSONObject): Map<String, Any> {
        val map = mutableMapOf<String, Any>()
        val keys = jsonObject.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = jsonObject.get(key)
            map[key] = when (value) {
                is JSONObject -> jsonToMap(value)
                else -> value
            }
        }
        return map
    }

    fun initialize(context: Context, channel: MethodChannel) {
        this.channel = channel
        DiscoveryManager.init(context.applicationContext, null)
        mDiscoveryManager = DiscoveryManager.getInstance()
        mDiscoveryManager?.addListener(this)
        mDiscoveryManager?.pairingLevel = DiscoveryManager.PairingLevel.ON
    }

    fun startScan() {
        WebOSManager.mDeviceList.value = emptyList()
        isScan.value = true
        mDiscoveryManager?.start()
    }

    fun stopScan() {
        isScan.value = false
        mDiscoveryManager?.stop()
    }
    override fun onDeviceAdded(manager: DiscoveryManager?, device: ConnectableDevice?) {
        Log.d("onDeviceAdded", device.toString())
        val deviceJson = device.toString()
        val deviceInfo = jsonDeviceInfoToMap(deviceJson)
        Log.d("deviceMap", deviceInfo.toString())
        device?.let {
            val serviceNames = device.services.map { it.serviceName }
            Log.d("onDeviceAdded serviceNames", serviceNames.toString())

            if ("webOS TV" in serviceNames) {
                val currentList = mDeviceList.value ?: emptyList()
                Log.d("currentList", currentList.toString())

//                if (currentList.none { it.id == device.id }) {
                    // Create a map for the device information
//                    val deviceInfo = mapOf(
//                        ConnectableDevice.KEY_ID to device.id,
//                        ConnectableDevice.KEY_LAST_IP to device.lastKnownIPAddress,
//                        ConnectableDevice.KEY_FRIENDLY to device.friendlyName,
//                        ConnectableDevice.KEY_MODEL_NAME to device.modelName,
//                        ConnectableDevice.KEY_MODEL_NUMBER to device.modelNumber,
//                        ConnectableDevice.KEY_LAST_CONNECTED to device.lastConnected,
//                        ConnectableDevice.KEY_LAST_DETECTED to device.lastDetection,
//                    )

                    // Update device list and notify Flutter
                    mDeviceList.postValue(currentList + device)
                    WebOSManager.mDeviceList.postValue(currentList + device)
                    controller.setLoading(false)
                    stopScan()
                    channel?.invokeMethod("onDeviceAdded", deviceInfo) // Sending device info to Flutter
//                }
            }
        }
    }


    override fun onDeviceUpdated(manager: DiscoveryManager?, device: ConnectableDevice?) {
        Log.d("onDeviceUpdated", device.toString())
        device?.let {
            val serviceNames = device.services.map { it.serviceName }
            Log.d("serviceNames", serviceNames.toString())
            if ("webOS TV" in serviceNames) {
                val currentList = mDeviceList.value ?: emptyList()
                if (currentList.none { it.id == device.id }) {
                    val deviceInfo = mapOf(
                        "id" to device.id,
                        "friendlyName" to device.friendlyName,
                        "modelName" to device.modelName,
                        "lastKnownIPAddress" to device.lastKnownIPAddress,
                        "lastSeenOnWifi" to device.lastSeenOnWifi
                    )
                    mDeviceList.postValue(currentList + device)
                    WebOSManager.mDeviceList.postValue(currentList + device)
                    controller.setLoading(false)
                    stopScan()
                    channel?.invokeMethod("onDeviceUpdated", deviceInfo) // Send device info to Flutter
                }
            }
        }
    }


    override fun onDeviceRemoved(manager: DiscoveryManager?, device: ConnectableDevice?) {
        Log.d("onDeviceRemoved", device.toString())
    }

    override fun onDiscoveryFailed(manager: DiscoveryManager?, error: ServiceCommandError?) {
        Log.d("onDiscoveryFailed", error.toString())
    }

    fun deviceProvision() {
        if (DeviceListener.mDevice != null) {
            webOSTVService = DeviceListener.mDevice!!.getServiceByName("webOS TV") as WebOSTVService
            Log.d("webOSTVService", webOSTVService.toString())

            if (webOSTVService != null) {
                val uri = "luna://com.webos.service.petcareservice/mqtt/executeProvisioning"
//                val uri = "ssap://system/getSystemInfo"
                val payload = JSONObject()

                val command = ServiceCommand<ResponseListener<Any>>(
                    webOSTVService,
                    uri,
                    payload,
                    true,
                    object : ResponseListener<Any> {
                        override fun onSuccess(response: Any) {
                            Log.d("Provision Response", response.toString())
                            // Send only the necessary response data to Flutter
                            channel?.invokeMethod("deviceProvision", mapOf("success" to true, "response" to response.toString()))
                        }

                        override fun onError(error: ServiceCommandError) {
                            Log.d("Provision Error", error.toString())
                            // Send only the necessary error data to Flutter
                            channel?.invokeMethod("deviceProvision", mapOf("success" to false, "error" to error.toString()))
                        }
                    })

                command.send()
            } else {
                Log.d("WebOSTVService not available", "Check the webOS TV Service")
            }
        } else {
            Log.d("Connection Status", "Check the connection")
        }
    }
}
