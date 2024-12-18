package com.lge.petcarezone.module.network.checker

sealed class NetworkState {
    object WifiConnected : NetworkState()
    object NotConnected : NetworkState()
}
