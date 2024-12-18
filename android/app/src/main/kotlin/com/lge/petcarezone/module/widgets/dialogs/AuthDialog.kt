package com.lge.petcarezone.module.widgets.dialogs

import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Card
import androidx.compose.material3.Divider
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.lge.petcarezone.constants.AppFont
import com.lge.petcarezone.module.activities.IActivityController
import com.lge.petcarezone.module.network.DeviceListener
import com.lge.petcarezone.module.network.DiscoveryListener
import com.lge.petcarezone.module.network.WebOSManager
import com.lge.petcarezone.module.widgets.commons.IsDarkService
import kotlinx.coroutines.launch

@Composable
fun AuthDialog(onDismissRequest: () -> Unit, controller: IActivityController) {
    val isDarkService = IsDarkService(controller.isDark.value ?: false)

    var pinCode by remember { mutableStateOf("") }
    val maxLength = 8

    Dialog(onDismissRequest = { onDismissRequest() }) {
        Card(
            modifier = Modifier
                .width(283.dp)
                .height(240.dp),
            shape = RoundedCornerShape(20.dp),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(isDarkService.getBackgroundColor())
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(8f),
                    contentAlignment = Alignment.TopCenter
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(isDarkService.getBackgroundColor())
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(20.dp)
                                .height(48.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "Please enter the PIN code\ndisplayed on the screen.",
                                style = TextStyle(
                                    fontFamily = AppFont.appleSDGothicNeo,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 18.sp,
                                    color = if (controller.isDark.value == true) Color(
                                        0xFFFFFFFF
                                    ) else Color(0xFF2D2D2D)
                                ),
                                textAlign = TextAlign.Center
                            )
                        }

                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(62.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            TextField(
                                value = pinCode,
                                onValueChange = { newValue ->
                                    if (newValue.length <= maxLength && newValue.all { it.isDigit() }) {
                                        pinCode = newValue
                                    }
                                },
                                placeholder = {
                                    Box(
                                        modifier = Modifier.fillMaxSize(),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            fontFamily = AppFont.appleSDGothicNeo,
                                            fontWeight = FontWeight.SemiBold,
                                            fontSize = 26.sp,
                                            color = if (controller.isDark.value == true) Color(
                                                0xFF8F8F8F
                                            ) else Color(0xFFB3B3B3),
                                            text = "PIN code",
                                        )
                                    }
                                },
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                                singleLine = true,
                                modifier = Modifier
                                    .width(150.dp)
                                    .fillMaxHeight(),
                                textStyle = TextStyle(
                                    fontFamily = AppFont.appleSDGothicNeo,
                                    fontSize = 26.sp,
                                    fontWeight = FontWeight.SemiBold,
                                ),
                                colors = TextFieldDefaults.colors(
                                    focusedTextColor = if (controller.isDark.value == true) Color(
                                        0xFFFFFFFF
                                    ) else Color(0xFF737373),
                                    disabledTextColor = if (controller.isDark.value == true) Color(
                                        0xFFFFFFFF
                                    ) else Color(0xFF737373),
                                    focusedContainerColor = isDarkService.getBackgroundColor(),
                                    unfocusedContainerColor = isDarkService.getBackgroundColor(),
                                    disabledContainerColor = isDarkService.getBackgroundColor(),
                                    cursorColor = if (controller.isDark.value == true) Color(
                                        0xFFFFFFFF
                                    ) else Color(0xFF737373),
                                    focusedIndicatorColor = if (controller.isDark.value == true) Color(
                                        0xFFFFFFFF
                                    ) else Color(0xFF737373),
                                    unfocusedIndicatorColor = if (controller.isDark.value == true) Color(
                                        0xFF4D4D4D
                                    ) else Color(0xFFCFD3DB)
                                ),
                            )
                        }
                    }
                }
                Divider(color = isDarkService.getButtonColor())
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(2f),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxHeight()
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(5f)
                                .fillMaxHeight()
                                .clickable {
                                    onDismissRequest()
                                },
                        ) {
                            Text(
                                text = "Cancel",
                                style = TextStyle(
                                    fontFamily = AppFont.appleSDGothicNeo,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 18.sp,
                                    color = if (controller.isDark.value == true) Color(0xFFB3B3B3) else Color(
                                        0xFF565656
                                    )
                                ),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(10.dp),
                                textAlign = TextAlign.Center
                            )
                        }
                        Box(
                            modifier = Modifier
                                .weight(5f)
                                .fillMaxHeight()
                                .alpha(if (pinCode.length == maxLength) 1.0f else 0.3f)
                                .clickable(enabled = pinCode.length == maxLength) {
                                    DeviceListener.sendPairingKey(pinCode)
                                    onDismissRequest()
                                },
                        ) {
                            Text(
                                text = "Certification",
                                style = TextStyle(
                                    fontFamily = AppFont.appleSDGothicNeo,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 18.sp,
                                    color = if (controller.isDark.value == true) Color(
                                        0xFFB3B3B3
                                    ) else Color(0xFF565656)
                                ),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(10.dp),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
        }
    }
}
