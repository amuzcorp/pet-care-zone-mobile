package com.lge.petcarezone.module.settings.appSetting

class AppSettingRepository(private val appSettingDao: AppSettingDao) {
    suspend fun getSetting(): AppSettingEntity? {
        return appSettingDao.getSetting()
    }

    suspend fun saveSetting(setting: AppSettingEntity) {
        appSettingDao.insert(setting)
    }

    suspend fun createDefault() {
        appSettingDao.insert(
            AppSettingEntity(
                id = 0,
                layout = 0,
                isDark = false
            )
        )
    }
}
