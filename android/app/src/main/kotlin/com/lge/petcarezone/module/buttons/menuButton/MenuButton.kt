package com.lge.petcarezone.module.buttons.menuButton

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.lge.petcarezone.module.activities.IActivityController
import com.lge.petcarezone.module.system.SystemRepository
//import com.lge.petcarezone.module.widgets.dialogs.ConnectDialog
//import com.lge.petcarezone.module.connection.ConnectionView
import com.lge.petcarezone.module.network.DiscoveryListener
import com.lge.petcarezone.module.network.checker.NetworkChecker
import com.lge.petcarezone.module.network.checker.NetworkState
//import com.lge.petcarezone.module.widgets.dialogs.AuthDialog

class MenuButton(private val controller: IActivityController) {
    @Composable
    fun Render() {
        val context = LocalContext.current

        val networkChecker = NetworkChecker(context)
        val networkState = networkChecker.networkState.collectAsState().value

        var showDialog by remember { mutableStateOf(false) }

        val isPressed = remember { mutableStateOf(false) }
//        val isEnable = remember { context is ConnectionView }
//        print("isEnable $isEnable")

        networkChecker.startMonitoring()

        BoxWithConstraints {
            val size = (maxWidth.value / 1.7).dp
            Box(
                modifier = Modifier
                    .size(size)
                    .background(
                        color = Color.Unspecified,
                        shape = RoundedCornerShape(20.dp)
                    )
                    .pointerInput(Unit) {
                        detectTapGestures(
                            onPress = {
                                isPressed.value = true
                                showDialog = true
                                tryAwaitRelease()
                                isPressed.value = false
                            }
                        )
                    },
                contentAlignment = Alignment.Center,
            ) {
            }
        }

        when (networkState) {
            is NetworkState.WifiConnected -> {
                val discoveryListener = DiscoveryListener(controller)
//                discoveryListener.initialize(context)
                discoveryListener.startScan()
//                ConnectDialog(
//                    controller = controller,
//                    onDismissRequest = { showDialog = true },
//                )
            }

            is NetworkState.NotConnected -> {
                Toast
                    .makeText(
                        context,
                        "Please check the Wi-Fi connection.",
                        Toast.LENGTH_SHORT
                    )
                    .show()
            }
        }
        networkChecker.stopMonitoring()
//        if (showDialog) {
//            AuthDialog(
//                controller = controller,
//                onDismissRequest = { showDialog = false }
//            )
//        }
    }
}
