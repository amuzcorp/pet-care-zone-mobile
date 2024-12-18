package com.lge.petcarezone.module.activities

import androidx.lifecycle.MutableLiveData
import kotlinx.coroutines.flow.StateFlow

interface IActivityController {
    val activityModel: IActivityModel

    var appId: MutableLiveData<Int>
    var layout: MutableLiveData<Int>
    var isDark: MutableLiveData<Boolean>

    val layoutId: MutableLiveData<Int>
    val name: MutableLiveData<String>
    val isLoading: StateFlow<Boolean>

    suspend fun dataInit()
    suspend fun reset()
    suspend fun update()
    fun setLoading(isLoading: Boolean)
}
