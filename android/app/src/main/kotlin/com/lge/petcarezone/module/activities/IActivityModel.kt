package com.lge.petcarezone.module.activities

import com.lge.petcarezone.module.settings.appSetting.AppSettingEntity
import com.lge.petcarezone.module.settings.database.AppDatabase
import com.lge.petcarezone.module.settings.appSetting.AppSettingRepository
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingEntity
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingRepository

interface IActivityModel {
    val database: AppDatabase
    val appRepository: AppSettingRepository
    val layoutRepository: LayoutSettingRepository

    var appId: Int
    var layout: Int
    var isDark: Boolean

    var layoutId: Int
    var name: String

    suspend fun dataInit()
    suspend fun dataInit(layoutId: Int)
    suspend fun reset(layoutSettingEntity: LayoutSettingEntity)
    suspend fun update(appSettingEntity: AppSettingEntity, layoutSettingEntity: LayoutSettingEntity)
}
