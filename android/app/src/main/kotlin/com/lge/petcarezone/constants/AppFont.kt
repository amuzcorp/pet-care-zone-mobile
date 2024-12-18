package com.lge.petcarezone.constants

import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.lge.petcarezone.R

object AppFont {
    val appleSDGothicNeo = FontFamily(
        Font(R.font.apple_sd_gothic_neo_eb, FontWeight.ExtraBold), // Extra Bold
        Font(R.font.apple_sd_gothic_neo_b, FontWeight.Bold),       // Bold
        Font(R.font.apple_sd_gothic_neo_h, FontWeight.Black),      // Heavy (Black)
        Font(R.font.apple_sd_gothic_neo_l, FontWeight.Light),      // Light
        Font(R.font.apple_sd_gothic_neo_m, FontWeight.Medium),     // Medium
        Font(R.font.apple_sd_gothic_neo_r, FontWeight.Normal),     // Regular (Normal)
        Font(R.font.apple_sd_gothic_neo_sb, FontWeight.SemiBold),  // Semi Bold
        Font(R.font.apple_sd_gothic_neo_t, FontWeight.Thin),       // Thin
//        Font(R.font.apple_sd_gothic_neo_ul, FontWeight.UltraLight) // Ultra Light
    )

    val sfPro = FontFamily(
        Font(R.font.sf_pro, FontWeight.Medium)
    )
}
