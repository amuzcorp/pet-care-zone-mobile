package com.lge.petcarezone.module.settings.layoutSetting

class LayoutSettingRepository(private val layoutSettingDao: LayoutSettingDao) {

    suspend fun getSetting(id: Int): LayoutSettingEntity? {
        return layoutSettingDao.getLayoutById(id)
    }

    suspend fun getSettingList(): List<LayoutSettingEntity>{
        return layoutSettingDao.getLayoutList()
    }

    suspend fun saveSetting(setting: LayoutSettingEntity) {
        layoutSettingDao.insert(setting)
    }

    suspend fun createDefaultHealthConditions() {
        layoutSettingDao.insert(
            LayoutSettingEntity(
                id = 0,
                name = "PetCareZone",
            )
        )
    }

}
