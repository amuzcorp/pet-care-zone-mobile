package com.lge.petcarezone.module.settings.appSetting

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "app_settings")
data class AppSettingEntity(
    @PrimaryKey
    val id: Int,
    val layout: Int,
    val isDark: Boolean
)
