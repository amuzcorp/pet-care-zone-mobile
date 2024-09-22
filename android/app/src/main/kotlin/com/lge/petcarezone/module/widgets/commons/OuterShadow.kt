package com.lge.petcarezone.module.widgets.commons

import android.graphics.BlurMaskFilter
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp


fun Modifier.outerShadow(
    color: Color = Color.Black,
    offsetX: Dp = 0.dp,
    offsetY: Dp = 0.dp,
    blurRadius: Dp = 0.dp,
    shapeRadius: Dp = 0.dp,
) = composed {
    val paint = remember { Paint() }
    val blurRadiusPx = with(LocalDensity.current) { blurRadius.toPx() }
    val maskFilter = remember(blurRadiusPx) {
        BlurMaskFilter(blurRadiusPx, BlurMaskFilter.Blur.NORMAL)
    }

    drawBehind {
        val frameworkPaint = paint.asFrameworkPaint()
        frameworkPaint.color = color.toArgb()
        frameworkPaint.maskFilter = if (blurRadius != 0.dp) maskFilter else null

        val leftPixel = offsetX.toPx()
        val topPixel = offsetY.toPx()
        val rightPixel = size.width + leftPixel
        val bottomPixel = size.height + topPixel

        drawIntoCanvas { canvas ->
            if (shapeRadius > 0.dp) {
                val radiusPx = shapeRadius.toPx()
                canvas.drawRoundRect(
                    left = leftPixel,
                    top = topPixel,
                    right = rightPixel,
                    bottom = bottomPixel,
                    radiusX = radiusPx,
                    radiusY = radiusPx,
                    paint = paint,
                )
            } else {
                canvas.drawRect(
                    left = leftPixel,
                    top = topPixel,
                    right = rightPixel,
                    bottom = bottomPixel,
                    paint = paint,
                )
            }
        }
    }
}
