package com.lge.petcarezone.constants

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor

object AppColor {
    object DarkMode {
        val backgroundColor = Color(0xFF1B1B1B)
        val buttonColor = Color(0xFF3B3B3B)
        val buttonBrush = Brush.verticalGradient(
            colors = listOf(
                Color(0xFF3B3B3B),
                Color(0xFF3B3B3B)
            )
        )
        val darkInnerColor = Color(0xFF070707)
        val lightInnerColor = Color(0xFFAFAFAF)
        val borderColor = Color(0xFF000000)
        val pressBorderColor = Color(0xFF00CDA8)
        val textColor = Color.White
    }

    object LightMode {
        val backgroundColor = Color(0xFFEFF1F4)
        val buttonColor = Color(0xFFCFD3DB)
        val darkInnerColor = Color(0xFF9EA5B0)
        val lightInnerColor = Color(0xFFF7FAFF)
        val borderColor = Color(0xFF78808D)
        val pressBorderColor = Color(0x4C00CDA8)
        val textColor = Color(0xFF565656)
    }

    object CustomColor {
        val check = Color(0xFF009379)

        val orange = Color(0xFFFF853C)
        val strawberry = Color(0xFFF44279)
        val lemon = Color(0xFFFFCD00)
        val magenta = Color(0xFFFF4EF4)
        val ultramarineBlue = Color(0xFF533DE8)
        val cyan = Color(0xFF2A8DFF)
        val violet = Color(0xFFBA42FF)
        val lime = Color(0xFF8CDC27)
        val realRed = Color(0xFFFF3E3E)
    }
}
