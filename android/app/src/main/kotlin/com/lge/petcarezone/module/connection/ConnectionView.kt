package com.lge.petcarezone.module.connection

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.lge.petcarezone.module.activities.IActivityController
import com.lge.petcarezone.module.activities.defaultMode.DefaultModeControllerImpl
import com.lge.petcarezone.module.buttons.menuButton.MenuButton
import com.lge.petcarezone.module.splash.SplashController
import com.lge.petcarezone.module.widgets.commons.IsDarkService
import com.lge.petcarezone.module.widgets.commons.LoadingPage

class ConnectionView : ComponentActivity() {
    private lateinit var controller: DefaultModeControllerImpl
    private var isDataInitialized by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        controller = DefaultModeControllerImpl(this)

        setContent {
//            LoadingPage()
            LaunchedEffect(Unit) {
                controller.dataInit()
                isDataInitialized = true
            }
            if (isDataInitialized) {
                Render(controller)

            } else {
                LoadingPage()
            }
        }
    }

    @Composable
    fun Render(controller: IActivityController) {
        var selectedItem by remember { mutableStateOf<Int?>(null) }

        Column(
            modifier = Modifier
                .fillMaxSize()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(4f)
                    .zIndex(1f)
            ) {
                Column {
                    Row(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                    ) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            contentAlignment = Alignment.Center
                        ) {
                            val menuButton = MenuButton(controller)
                            menuButton.Render()
                        }
                    }
                }
            }
        }
    }
}
