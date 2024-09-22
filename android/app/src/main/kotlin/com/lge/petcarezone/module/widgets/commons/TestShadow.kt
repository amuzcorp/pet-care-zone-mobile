package com.lge.petcarezone.module.widgets.commons

import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.ClipOp
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawOutline
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.isSpecified
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.isSpecified

data class Shadow(
    val color: Color = Color.Black,
    val blurRadius: Dp = 0.dp,
    val spreadRadius: Dp = 0.dp,
    val offset: DpOffset = DpOffset.Zero,
    val inset: Boolean = false,
)

fun Modifier.testShadow(
    vararg shadowList: Shadow,
    shape: Shape = RectangleShape,
    clip: Boolean = true,
): Modifier {
    return drawWithCache {
        onDrawWithContent {
            fun drawShadow(shadow: Shadow) {
                val color: Color = shadow.color;
                val blurRadius: Dp = shadow.blurRadius;
                val spreadRadius: Dp = shadow.spreadRadius;
                val offset: DpOffset = shadow.offset;
                val inset: Boolean = shadow.inset;

                require(color.isSpecified) { "color must be specified." }
                require(blurRadius.isSpecified) { "blurRadius must be specified." }
                require(blurRadius.value >= 0f) { "blurRadius can't be negative." }
                require(spreadRadius.isSpecified) { "spreadRadius must be specified." }
                require(offset.isSpecified) { "offset must be specified." }

                drawIntoCanvas { canvas ->
                    val spreadRadiusPx = spreadRadius.toPx().let { spreadRadiusPx ->
                        when {
                            inset -> -spreadRadiusPx
                            else -> spreadRadiusPx
                        }
                    }

                    val hasSpreadRadius = spreadRadiusPx != 0f

                    val shadowOutline = shape.createOutline(size = when {
                        hasSpreadRadius -> size.let { (width, height) ->
                            (2 * spreadRadiusPx).let { outset ->
                                Size(
                                    width = width + outset, height = height + outset
                                )
                            }
                        }

                        else -> size
                    }, layoutDirection = layoutDirection, density = this)

                    canvas.save()

                    if (inset) {
                        val boxOutline = when {
                            hasSpreadRadius -> shape.createOutline(
                                size = size, layoutDirection = layoutDirection, density = this
                            )

                            else -> shadowOutline
                        }

                        canvas.clipToOutline(boxOutline)

                        canvas.saveLayer(boxOutline.bounds, Paint().apply {
                            colorFilter = ColorFilter.colorMatrix(
                                ColorMatrix(
                                    floatArrayOf(
                                        1f, 0f, 0f, 0f, 0f,
                                        0f, 1f, 0f, 0f, 0f,
                                        0f, 0f, 1f, 0f, 0f,
                                        0f, 0f, 0f, -1f, 255f * color.alpha
                                    )
                                )
                            )
                        })
                    }

                    canvas.drawOutline(outline = shadowOutline, paint = Paint().also { paint ->
                        paint.asFrameworkPaint().apply {
                            this.color = Color.Transparent.toArgb()
                            setShadowLayer(
                                blurRadius.toPx(),
                                offset.x.toPx() - spreadRadiusPx,
                                offset.y.toPx() - spreadRadiusPx,
                                color.toArgb(),
                            )
                        }
                    })

                    if (inset) {
                        canvas.restore()
                    }

                    canvas.restore()
                }
            }

            for (shadow in shadowList.filter { !it.inset }) {
                drawShadow(shadow)
            }

            drawContent()

            for (shadow in shadowList.filter { it.inset }) {
                drawShadow(shadow)
            }
        }
    }.let { modifier -> if (clip) modifier.clip(shape) else modifier }
}

fun Canvas.clipToOutline(
    outline: Outline,
    clipOp: ClipOp = ClipOp.Intersect,
) {
    when (outline) {
        is Outline.Generic -> clipPath(path = outline.path, clipOp = clipOp)

        is Outline.Rectangle -> clipRect(rect = outline.rect, clipOp = clipOp)

        is Outline.Rounded -> clipPath(
            path = Path().apply { addRoundRect(outline.roundRect) }, clipOp = clipOp
        )
    }
}
