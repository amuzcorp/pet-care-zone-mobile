package com.lge.petcarezone

import android.content.Intent
import android.net.Uri
import java.io.File
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
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lge.petcarezone/discovery"
    private val LOGCHANNEL = "com.lge.petcarezone/logs"
    private val MEDIACHANNEL = "com.lge.petcarezone/media"
    private lateinit var discoveryListener: DiscoveryListener

    private fun scanFile(file: File) {
        val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
        val contentUri: Uri = Uri.fromFile(file)
        mediaScanIntent.data = contentUri
        sendBroadcast(mediaScanIntent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val mediaChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIACHANNEL)
        mediaChannel.setMethodCallHandler { methodCall, result ->
            if (methodCall.method == "scanFile") {
                val filePath = methodCall.argument<String>("filePath")
                scanFile(File(filePath!!))
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        val logChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOGCHANNEL)
        logChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "onMessage" -> {
                    result.success(call.arguments)
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
                "connectToDevice" -> {
                    val deviceJson = call.argument<String>("device")
                    deviceJson?.let {
                        val device = jsonToDevice(it)
                        device?.let { device ->
                            discoveryListener.connectToDevice(device)
                        } ?: result.error("INVALID_JSON", "Failed to convert JSON to ConnectableDevice", null)
                    } ?: result.error("UNAVAILABLE", "Device JSON not available.", null)
                }
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
                "requestParingKey" -> {
                    val deviceJson = call.argument<String>("device")
                    deviceJson?.let {
                        val device = jsonToDevice(it)
                        device?.let { device ->
                            DeviceListener.requestParingKey(this, device)
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
                "webOSRequest" -> {
                    val uri = call.argument<String>("uri")
                    val payload = call.argument<Map<String, Any>>("payload")

                    if (uri != null && payload != null) {
                        discoveryListener.webOSRequest(uri, JSONObject(payload))
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Uri or Payload missing", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        discoveryListener.initialize(this, channel)
        WebOSTVServiceSocketClient.setMethodChannel(logChannel)
    }
}
