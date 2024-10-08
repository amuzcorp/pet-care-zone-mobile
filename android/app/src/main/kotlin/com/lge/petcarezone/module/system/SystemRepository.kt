package com.lge.petcarezone.module.system

import android.content.ContentResolver
import android.content.Context
import android.os.Vibrator
import android.provider.Settings

class SystemRepository(context: Context) {
    // 시스템 관련 명령 내리는 클래스
    private val contentResolver: ContentResolver = context.contentResolver

    fun getBrightness(): Int {
        return Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, 0)
    }

    fun setBrightness(value: Int) {
        Settings.System.putInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, value)
    }
}
