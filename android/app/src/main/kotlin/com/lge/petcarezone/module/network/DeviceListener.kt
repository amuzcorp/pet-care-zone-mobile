package com.lge.petcarezone.module.network

import android.content.Context
import android.util.Log
import com.connectsdk.device.ConnectableDevice
import com.connectsdk.device.ConnectableDeviceListener
import com.connectsdk.service.DeviceService
import com.connectsdk.service.command.ServiceCommandError
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

object DeviceListener : ConnectableDeviceListener {
    private var channel: MethodChannel? = null
    private var appContext: Context? = null
    var mDevice: ConnectableDevice? = null

    private fun createDeviceServiceFromJson(serviceJson: JSONObject?): DeviceService? {
        if (serviceJson == null) return null

        return try {
            DeviceService.getService(serviceJson)
        } catch (e: Exception) {
            Log.e("DeviceListener", "Failed to create DeviceService from JSON", e)
            null
        }
    }

    fun jsonToDevice(json: String): ConnectableDevice? {
        return try {
            val jsonObject = JSONObject(json)
            val device = ConnectableDevice(jsonObject)

            val servicesJson = jsonObject.optJSONObject("services")
            servicesJson?.let { services ->
                val servicesMap = mutableMapOf<String, DeviceService>()
                val keys = services.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val serviceJson = services.optJSONObject(key)
                    val deviceService = createDeviceServiceFromJson(serviceJson)
                    deviceService?.let { servicesMap[key] = it }
                }
                setServicesField(device, servicesMap)
            }
            device
        } catch (e: Exception) {
            Log.e("DeviceListener", "Failed to convert JSON to ConnectableDevice", e)
            null
        }
    }

    private fun setServicesField(device: ConnectableDevice, servicesMap: Map<String, DeviceService>) {
        try {
            val servicesField = ConnectableDevice::class.java.getDeclaredField("services")
            servicesField.isAccessible = true
            servicesField.set(device, servicesMap)
        } catch (e: Exception) {
            Log.e("DeviceListener", "Failed to set services field in ConnectableDevice", e)
        }
    }

    fun initialize(context: Context, device: ConnectableDevice?) {
        this.channel = channel
        appContext = context.applicationContext
        mDevice = device
        mDevice?.let { device ->
            // 장치의 서비스 목록을 가져와서 로그에 출력
            val allServices = device.services
            if (allServices.isEmpty()) {
                Log.d("DeviceListener", "No services available")
            } else {
                allServices.forEach { service ->
                    Log.d("DeviceListener", "Service: $service")
                }
            }

            // 장치 상태를 로그에 출력
            Log.d("DeviceListener", "Device: $device")

            // 장치에 리스너를 추가
            device.addListener(this)

            // 장치와의 연결을 시도
            device.setPairingType(DeviceService.PairingType.PIN_CODE)
            device.connect()
        } ?: run {
            Log.e("DeviceListener", "Device is null")
        }
    }

    fun sendPairingKey(pinCode: String) {
        try {
            mDevice?.sendPairingKey(pinCode)
            Log.d("sendPairingKey", "Pairing key sent successfully")
            channel?.invokeMethod("sendPairingKey", mapOf("status" to "success"))
        } catch (e: Exception) {
            Log.d("sendPairingKey", "Failed to send pairing key: ${e.message}")
            channel?.invokeMethod("sendPairingKey", mapOf("status" to "failed", "error" to e.message))
        }
    }


    override fun onDeviceReady(device: ConnectableDevice?) {
        WebOSManager.initialize(device)
        channel?.invokeMethod("deviceReady", "Successfully connected.")
    }

    override fun onDeviceDisconnected(device: ConnectableDevice?) {
        channel?.invokeMethod("deviceDisconnected", "Please check the code.")
    }
    override fun onPairingRequired(
        device: ConnectableDevice?,
        service: DeviceService?,
        pairingType: DeviceService.PairingType?
    ) {
    }

    override fun onCapabilityUpdated(
        device: ConnectableDevice?,
        added: MutableList<String>?,
        removed: MutableList<String>?
    ) {
    }

    override fun onConnectionFailed(device: ConnectableDevice?, error: ServiceCommandError?) {
    }

}
