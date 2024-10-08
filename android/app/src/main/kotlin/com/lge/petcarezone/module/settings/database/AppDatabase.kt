package com.lge.petcarezone.module.settings.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.lge.petcarezone.module.settings.appSetting.AppSettingDao
import com.lge.petcarezone.module.settings.appSetting.AppSettingEntity
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingDao
import com.lge.petcarezone.module.settings.layoutSetting.LayoutSettingEntity

@Database(
    entities = [AppSettingEntity::class, LayoutSettingEntity::class],
    version = 2,
    exportSchema = true
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun appSettingDao(): AppSettingDao
    abstract fun layoutSettingDao(): LayoutSettingDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "app_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
