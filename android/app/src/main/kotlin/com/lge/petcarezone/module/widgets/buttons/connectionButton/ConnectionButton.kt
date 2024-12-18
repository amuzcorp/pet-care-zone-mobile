package com.lge.petcarezone.module.widgets.buttons.connectionButton

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieConstants
import com.lge.petcarezone.R
import com.lge.petcarezone.constants.AppColor
import com.lge.petcarezone.module.activities.IActivityController
import com.lge.petcarezone.module.connection.ConnectionView
import com.lge.petcarezone.module.system.SystemRepository
import com.lge.petcarezone.module.widgets.dialogs.ConnectDialog
import com.lge.petcarezone.module.widgets.commons.IsDarkService
import com.lge.petcarezone.module.widgets.commons.innerShadow
import com.lge.petcarezone.module.widgets.commons.outerShadow
import kotlinx.coroutines.launch

class ConnectionButton(private val controller: IActivityController) {
    @Composable
    fun Render() {
        val context = LocalContext.current
        val systemRepository = SystemRepository(context)

        val isDark = controller.isDark.value ?: false
        val menuButton = 0

        var showDialog by remember { mutableStateOf(false) }
        val isPressed = remember { mutableStateOf(false) }


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

        if (showDialog) {
            ConnectDialog(
                controller = controller,
                onDismissRequest = { showDialog = false },
            )
        }
    }
}
