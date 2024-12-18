package com.lge.petcarezone.module.splash

import android.content.Context
import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.MutableLiveData
import com.lge.petcarezone.module.connection.ConnectionView
import com.lge.petcarezone.module.settings.appSetting.AppSettingEntity
import com.lge.petcarezone.module.settings.appSetting.AppSettingRepository
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingRepository

class SplashController(private val context: Context) {
    private val splashModel = SplashModel(context)
    private val appSettingRepository: AppSettingRepository = splashModel.getAppRepository()
    private val layoutSettingRepository: LayoutSettingRepository = splashModel.getLayoutRepository()
    private var appSettingEntity: MutableLiveData<AppSettingEntity> = MutableLiveData()

    suspend fun dataInit() {
        this.appSettingEntity.value = appSettingRepository.getSetting()
    }

    // app_settings table init
    suspend fun appInit() {
        if (appSettingRepository.getSetting() == null) {
            try {
                appSettingRepository.createDefault()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    suspend fun layoutInit() {
        layoutSettingRepository.createDefaultHealthConditions()
    }

    fun routeConnectionMode() {
        context.startActivity(Intent(context, ConnectionView::class.java))
    }


}
