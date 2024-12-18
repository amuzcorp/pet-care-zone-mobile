package com.lge.petcarezone.module.settings.layoutSetting

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "layout_settings")
data class LayoutSettingEntity(
    @PrimaryKey
    var id: Int,
    var name: String,
)
