package com.lge.petcarezone.module.widgets.commons

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.LottieConstants
import com.airbnb.lottie.compose.rememberLottieAnimatable
import com.airbnb.lottie.compose.rememberLottieComposition
import com.lge.petcarezone.R
import com.lge.petcarezone.constants.AppFont


@Composable
fun LoadingPage() {
    val composition by rememberLottieComposition(LottieCompositionSpec.RawRes(R.raw.loading))
    val lottieAnimatable = rememberLottieAnimatable()

    LaunchedEffect(composition) {
        composition?.let {
            lottieAnimatable.animate(
                composition = it,
                iterations = LottieConstants.IterateForever
            )
        }
    }
    Dialog(onDismissRequest = {}) {
        Box(
            modifier = Modifier
                .wrapContentSize(unbounded = true)
                .fillMaxSize()
//                .background(
//                    color = Color.Black.copy(alpha = 0.5f)
//                )
            ,
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
            ) {
                Box(
                    modifier = Modifier
                        .wrapContentSize(unbounded = true)
                        .fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column {
                        LottieAnimation(
                            composition = composition,
                            progress = lottieAnimatable.progress,
                            modifier = Modifier.fillMaxSize()
                        )
                        Text(
                            text = "Loading...",
                            style = TextStyle(
                                fontFamily = AppFont.appleSDGothicNeo,
                                fontWeight = FontWeight.Normal,
                                fontSize = 17.sp,
                                color = Color(0xFFFFFFFF)
                            )
                        )
                    }

                }
            }

        }
    }
}
