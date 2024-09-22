package com.lge.petcarezone

import androidx.lifecycle.MutableLiveData
import com.connectsdk.service.webos.WebOSTVServiceSocketClient
import com.lge.petcarezone.module.activities.IActivityController
import com.lge.petcarezone.module.activities.IActivityModel
import com.lge.petcarezone.module.network.DeviceListener
import com.lge.petcarezone.module.network.DeviceListener.jsonToDevice
import com.lge.petcarezone.module.network.DiscoveryListener
import com.lge.petcarezone.module.network.WebOSManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.flow.StateFlow

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lge.petcarezone/discovery"
    private val LOGCHANNEL = "com.lge.petcarezone/logs"
    private lateinit var discoveryListener: DiscoveryListener

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val logChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOGCHANNEL)
        logChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "onMessage" -> {
                    result.success(call.arguments())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Discovery Channel
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        discoveryListener = DiscoveryListener(object : IActivityController {
            override val activityModel: IActivityModel
                get() = TODO("Not yet implemented")
            override var appId: MutableLiveData<Int>
                get() = TODO("Not yet implemented")
                set(value) {}
            override var layout: MutableLiveData<Int>
                get() = TODO("Not yet implemented")
                set(value) {}
            override var isDark: MutableLiveData<Boolean>
                get() = TODO("Not yet implemented")
                set(value) {}
            override val layoutId: MutableLiveData<Int>
                get() = TODO("Not yet implemented")
            override val name: MutableLiveData<String>
                get() = TODO("Not yet implemented")
            override val isLoading: StateFlow<Boolean>
                get() = TODO("Not yet implemented")

            override suspend fun dataInit() {
                TODO("Not yet implemented")
            }

            override suspend fun reset() {
                TODO("Not yet implemented")
            }

            override suspend fun update() {
                TODO("Not yet implemented")
            }

            override fun setLoading(loading: Boolean) {
            }
        })
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startScan" -> {
                    discoveryListener.startScan()
                }
                "stopScan" -> {
                    discoveryListener.stopScan()
                }
                "initialize" -> {
                    val deviceJson = call.argument<String>("device")
                    deviceJson?.let {
                        val device = jsonToDevice(it)
                        device?.let { device ->
                            DeviceListener.initialize(this, device)
                        } ?: result.error("INVALID_JSON", "Failed to convert JSON to ConnectableDevice", null)
                    } ?: result.error("UNAVAILABLE", "Device JSON not available.", null)
                }
                "sendPairingKey" -> {
                    val pinCode = call.argument<String>("pinCode")
                    pinCode?.let { DeviceListener.sendPairingKey(it) }
                    result.success("Send pairing key successfully!");
                }
                "deviceProvision" -> {
                    discoveryListener.deviceProvision()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        discoveryListener.initialize(this, channel)
        WebOSTVServiceSocketClient.setMethodChannel(logChannel)
    }
}
