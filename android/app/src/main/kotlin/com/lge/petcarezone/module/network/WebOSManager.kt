package com.lge.petcarezone.module.network

import android.util.Log
import androidx.lifecycle.MutableLiveData
import com.connectsdk.device.ConnectableDevice
import com.connectsdk.service.WebOSTVService
import com.connectsdk.service.capability.KeyControl

object WebOSManager {
    var mDeviceList: MutableLiveData<List<ConnectableDevice>> = MutableLiveData()
    private var mDevice: ConnectableDevice? = null
    private var webOSTVService: WebOSTVService? = null

    fun initialize(device: ConnectableDevice?) {
        mDevice = device
        webOSTVService = device!!.getServiceByName("webOS TV") as WebOSTVService
    }

    fun getDevice(): ConnectableDevice? {
        Log.d("mdeviceee", "initialize: $mDevice")
        return mDevice
    }

    fun sendPairingKey(pinCode: String) {
        mDevice?.sendPairingKey(pinCode)
    }

    fun volumeUP() {
        webOSTVService!!.volumeControl.volumeUp(null)
    }

    fun volumeDown() {
        webOSTVService!!.volumeControl.volumeDown(null)
    }

    fun connectMouse() {
        webOSTVService!!.connectMouse()
        webOSTVService!!.click()
    }

    fun sendLeft() {
        webOSTVService?.left(null)
    }

    fun sendUp() {
        webOSTVService?.up(null)
    }

    fun sendDown() {
        webOSTVService?.down(null)
    }

    fun sendRight() {
        webOSTVService?.right(null)
    }

    fun sendOk() {
        webOSTVService?.ok(null)
    }

    fun sendBack() {
        webOSTVService?.back(null)
    }

    fun sendKey() {
        webOSTVService?.sendKeyCode(KeyControl.KeyCode.NUM_0, null)
    }

    fun sendDelete() {
        webOSTVService?.sendDelete()
    }

    fun mouseMove(dx: Double, dy: Double) {
        webOSTVService?.move(dx, dy)
    }

    fun sendText(str: String) {
        webOSTVService?.sendText(str)
    }

}
