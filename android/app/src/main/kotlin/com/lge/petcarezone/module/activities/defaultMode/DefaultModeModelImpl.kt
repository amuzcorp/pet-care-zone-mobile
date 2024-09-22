package com.lge.petcarezone.module.activities.defaultMode

import android.content.Context
import com.lge.petcarezone.module.activities.IActivityModel
import com.lge.petcarezone.module.settings.appSetting.AppSettingEntity
import com.lge.petcarezone.module.settings.database.AppDatabase
import com.lge.petcarezone.module.settings.appSetting.AppSettingRepository
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingEntity
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingRepository

class DefaultModeModelImpl(context: Context) : IActivityModel {
    override val database = AppDatabase.getDatabase(context)
    override val appRepository = AppSettingRepository(database.appSettingDao())
    override val layoutRepository = LayoutSettingRepository(database.layoutSettingDao())

    override var appId: Int = 0
    override var layout: Int = 0
    override var isDark: Boolean = false


    override var layoutId: Int = 0
    override var name: String = ""

    override suspend fun dataInit() {
        val appData = appRepository.getSetting()
        val layoutData = layoutRepository.getSetting(0)

        if (appData != null) {
            this.appId = appData.id
            this.layout = appData.layout
            this.isDark = appData.isDark
        }

        if (layoutData != null) {
            this.layoutId = layoutData.id
            this.name = layoutData.name
        }
    }

    override suspend fun reset(layoutSettingEntity: LayoutSettingEntity) {
        layoutRepository.saveSetting(
            layoutSettingEntity
        )
    }

    override suspend fun dataInit(layoutId: Int) {}

    override suspend fun update(appSettingEntity: AppSettingEntity, layoutSettingEntity: LayoutSettingEntity) {}


}
