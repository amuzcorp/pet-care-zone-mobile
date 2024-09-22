package com.lge.petcarezone.module.splash

import android.content.Context
import com.lge.petcarezone.module.settings.database.AppDatabase
import com.lge.petcarezone.module.settings.appSetting.AppSettingRepository
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingRepository

class SplashModel(context: Context) {
    private val database = AppDatabase.getDatabase(context)
    private val appRepository = AppSettingRepository(database.appSettingDao())
    private val layoutRepository = LayoutSettingRepository(database.layoutSettingDao())

    fun getAppRepository(): AppSettingRepository {
        return this.appRepository
    }

    fun getLayoutRepository(): LayoutSettingRepository {
        return this.layoutRepository
    }
}
