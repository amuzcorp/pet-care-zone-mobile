package com.lge.petcarezone.module.widgets.commons

import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp

fun Modifier.innerBorder(
    strokeWidth: Dp,
    color: Color,
    cornerRadiusDp: Dp,
    offset : Offset = Offset.Zero
) = composed(
    factory = {
        val density = LocalDensity.current
        val strokeWidthPx = density.run { strokeWidth.toPx() }
        val cornerRadiusPx = density.run { cornerRadiusDp.toPx() }
        val halfStroke = strokeWidthPx / 2
        val topLeft = Offset(halfStroke + offset.x, halfStroke + offset.y)

        Modifier.drawBehind {
            val width = size.width -  topLeft.x*2
            val height = size.height - topLeft.y*2

            drawRoundRect(
                color = color,
                topLeft = topLeft,
                size = Size(width, height),
                cornerRadius = CornerRadius(cornerRadiusPx, cornerRadiusPx).shrink(halfStroke),
                style = Stroke(strokeWidthPx)
            )

        }
    }
)

private fun CornerRadius.shrink(value: Float): CornerRadius = CornerRadius(
    kotlin.math.max(0f, this.x - value),
    kotlin.math.max(0f, this.y - value)
)
