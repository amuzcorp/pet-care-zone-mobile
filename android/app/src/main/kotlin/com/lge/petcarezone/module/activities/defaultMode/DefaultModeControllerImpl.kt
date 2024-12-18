package com.lge.petcarezone.module.activities.defaultMode

import android.content.Context
import androidx.lifecycle.MutableLiveData
import com.lge.petcarezone.module.activities.IActivityController
import com.lge.petcarezone.module.activities.IActivityModel
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingEntity
import com.lge.petcarezone.module.system.SystemRepository
import com.lge.petcarezone.module.widgets.commons.IsDarkService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.Serializable

class DefaultModeControllerImpl(context: Context) : IActivityController {
    override val activityModel: IActivityModel = DefaultModeModelImpl(context)

    override var appId: MutableLiveData<Int> = MutableLiveData()
    override var layout: MutableLiveData<Int> = MutableLiveData()
    override var isDark: MutableLiveData<Boolean> = MutableLiveData()

    override val layoutId: MutableLiveData<Int> = MutableLiveData()
    override val name: MutableLiveData<String> = MutableLiveData()


    private val _isLoading = MutableStateFlow(false)
    override val isLoading: StateFlow<Boolean> get() = _isLoading

    override fun setLoading(isLoading: Boolean) {
        _isLoading.value = isLoading
    }

    override suspend fun dataInit() {
        activityModel.dataInit()

        this.appId.value = activityModel.appId
        this.layout.value = activityModel.layout
        this.isDark.value = activityModel.isDark

        this.layoutId.value = activityModel.layoutId
        this.name.value = activityModel.name

    }

    override suspend fun reset() {
        activityModel.reset(
            LayoutSettingEntity(
                id = 0,
                name = "Pet Carezone",
            )
        )
    }

    override suspend fun update() {}
}
