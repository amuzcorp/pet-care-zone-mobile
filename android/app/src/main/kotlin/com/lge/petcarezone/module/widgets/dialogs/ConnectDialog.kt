package com.lge.petcarezone.module.widgets.dialogs

import android.util.Log
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.ValueElement
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.lge.petcarezone.constants.AppFont
import com.lge.petcarezone.module.activities.IActivityController
import com.lge.petcarezone.module.network.DeviceListener
import com.lge.petcarezone.module.network.WebOSManager
import com.lge.petcarezone.module.widgets.commons.IsDarkService
import com.lge.petcarezone.module.widgets.commons.LoadingPage

@Composable
fun ConnectDialog(
    onDismissRequest: () -> Unit,
    controller: IActivityController
) {
    val context = LocalContext.current
    val isDarkService = IsDarkService(controller.isDark.value ?: false)
    var authDialog by remember { mutableStateOf(false) }
    val deviceList = WebOSManager.mDeviceList.observeAsState(emptyList())

    Log.d("ss", "ConnectDialog: $deviceList")
    Log.d("deviceeeee", "${deviceList.value}")

    Dialog(onDismissRequest = { onDismissRequest() }) {
        Card(
            modifier = Modifier
                .width(283.dp)
                .height(214.dp),
            shape = RoundedCornerShape(20.dp),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(isDarkService.getBackgroundColor())
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Please select the TV",
                            style = TextStyle(
                                fontFamily = AppFont.appleSDGothicNeo,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 18.sp,
                                color = isDarkService.getTextColor()
                            ),
                        )
                    }
                }
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                ) {
                    LazyColumn {
                        items(deviceList.value) { device ->
                            Box(
                                modifier = Modifier
                                    .fillMaxSize(),
                                contentAlignment = Alignment.CenterStart
                            ) {
                                Text(
                                    style = TextStyle(
                                        fontFamily = AppFont.appleSDGothicNeo,
                                        fontWeight = FontWeight.SemiBold,
                                        fontSize = 17.sp,
                                        color = isDarkService.getTextColor()
                                    ),
                                    modifier = Modifier
                                        .padding(16.dp)
                                        .pointerInput(Unit) {
                                            detectTapGestures(
                                                onTap = {
                                                    DeviceListener.initialize(context, device)
                                                    authDialog = true
                                                    print("get device: ${WebOSManager.getDevice()}")
                                                    Toast
                                                        .makeText(
                                                            context,
                                                            WebOSManager.getDevice()?.friendlyName + " 연결이 완료되었습니다.",
                                                            Toast.LENGTH_SHORT
                                                        )
                                                        .show()
                                                }
                                            )
                                        },
                                    text = device.friendlyName,
                                )
                            }
                            Divider(color = isDarkService.getButtonColor())

                        }
                    }
                }
            }
        }
    }

    if (deviceList.value.isEmpty()) {
        LoadingPage()
    }

    if (authDialog) {
        AuthDialog(
            controller = controller,
            onDismissRequest = { authDialog = false }
        )
    }
}
