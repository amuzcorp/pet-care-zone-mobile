package com.lge.petcarezone.module.splash

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect

import com.lge.petcarezone.module.network.DiscoveryListener

class SplashView : AppCompatActivity() {
    private lateinit var controller: SplashController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        controller = SplashController(this)

        setContent {
            Render()
        }
    }

    @Composable
    fun Render() {
        LaunchedEffect(key1 = true) {
            // db initialize
            controller.appInit()
            controller.layoutInit()
            // data Load
            controller.dataInit()
            // 화면 렌더링
            controller.routeConnectionMode()
            finish()
        }
    }
}
