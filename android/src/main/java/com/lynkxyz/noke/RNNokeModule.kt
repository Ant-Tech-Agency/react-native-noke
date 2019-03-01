//  Created by react-native-create-bridge

package com.lynkxyz.noke

import android.bluetooth.BluetoothAdapter
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.noke.nokemobilelibrary.*

class RNNokeModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private var mNokeService: NokeDeviceManagerService? = null
    private var currentNoke: NokeDevice? = null

    init {
        Companion.reactContext = reactContext
    }

    private val mServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, rawBinder: IBinder) {
//            Log.w(TAG, "ON SERVICE CONNECTED")

            //Store reference to service
            mNokeService = (rawBinder as NokeDeviceManagerService.LocalBinder).getService(NokeDefines.NOKE_LIBRARY_SANDBOX)

            //Register callback listener
            mNokeService!!.registerNokeListener(mNokeServiceListener)

            //Start bluetooth scanning
            mNokeService!!.startScanningForNokeDevices()

            if (!mNokeService!!.initialize()) {
//                Log.e(TAG, "Unable to initialize Bluetooth")
                emitDeviceEvent("onServiceConnected", writableMapOf(
                        "connected" to false
                ))
            } else {
                emitDeviceEvent("onServiceConnected", writableMapOf(
                        "connected" to true
                ))
            }
        }

        override fun onServiceDisconnected(classname: ComponentName) {
            mNokeService = null
            emitDeviceEvent("onServiceDisconnected", writableMapOf(
                    "connected" to false
            ))
        }
    }


    private val mNokeServiceListener = object : NokeServiceListener {
        override fun onNokeDiscovered(noke: NokeDevice) {
            currentNoke = noke
            mNokeService!!.connectToNoke(currentNoke)
            emitDeviceEvent("onNokeDiscovered", nokeDeviceInfo(noke))
        }

        override fun onNokeConnecting(noke: NokeDevice) {
            emitDeviceEvent("onNokeConnecting", nokeDeviceInfo(noke))
        }

        override fun onNokeConnected(noke: NokeDevice) {
            currentNoke = noke
            mNokeService!!.stopScanning()
            emitDeviceEvent("onNokeConnected", nokeDeviceInfo(noke))
        }

        override fun onNokeSyncing(noke: NokeDevice) {
            emitDeviceEvent("onNokeSyncing", nokeDeviceInfo(noke))
        }

        override fun onNokeUnlocked(noke: NokeDevice) {
            emitDeviceEvent("onNokeUnlocked", nokeDeviceInfo(noke))
        }

        override fun onNokeShutdown(noke: NokeDevice, isLocked: Boolean?, didTimeout: Boolean?) {
            emitDeviceEvent("onNokeShutdown", writableMapOf(
                    "noke" to nokeDeviceInfo(noke),
                    "isLocked" to isLocked,
                    "didTimeout" to didTimeout
            ))
        }

        override fun onNokeDisconnected(noke: NokeDevice) {
            mNokeService!!.startScanningForNokeDevices()
            mNokeService!!.setBluetoothScanDuration(8000)
            emitDeviceEvent("onNokeDisconnected", nokeDeviceInfo(noke))
        }

        override fun onDataUploaded(result: Int, message: String) {
            emitDeviceEvent("onDataUploaded", writableMapOf(
                    "result" to result,
                    "message" to message
            ))
        }

        override fun onBluetoothStatusChanged(bluetoothStatus: Int) {
            when(bluetoothStatus) {
                BluetoothAdapter.STATE_ON  -> startScan()
            }
            emitDeviceEvent("onBluetoothStatusChanged", writableMapOf(
                    "status" to bluetoothStatus
            ))

        }

        override fun onError(noke: NokeDevice?, error: Int, message: String) {
            emitDeviceEvent("onError", writableMapOf(
                    "noke" to nokeDeviceInfo(noke),
                    "message" to message,
                    "error" to error
                    ))
        }
    }

    override fun getName(): String {
        // Tell React the name of the module
        // https://facebook.github.io/react-native/docs/native-components-android.html#1-create-the-viewmanager-subclass
        return REACT_CLASS
    }

    override fun getConstants(): Map<String, Any>? {
        // Export any constants to be used in your native module
        // https://facebook.github.io/react-native/docs/native-modules-android.html#the-toast-module

        return mapOf<String, Any>(
                "NOKE_LOCK_STATE_LOCKED" to NokeDefines.NOKE_LOCK_STATE_LOCKED,
                "NOKE_LOCK_STATE_UNLOCKED" to NokeDefines.NOKE_LOCK_STATE_UNLOCKED,
                "NOKE_LOCK_STATE_UNSHACKLED" to NokeDefines.NOKE_LOCK_STATE_UNSHACKLED,
                "NOKE_LOCK_STATE_UNKNOWN" to NokeDefines.NOKE_LOCK_STATE_UNKNOWN,

                "ERROR_LOCATION_PERMISSIONS_NEEDED" to NokeMobileError.ERROR_LOCATION_PERMISSIONS_NEEDED,
                "ERROR_LOCATION_SERVICES_DISABLED" to NokeMobileError.ERROR_LOCATION_SERVICES_DISABLED,
                "ERROR_BLUETOOTH_DISABLED" to NokeMobileError.ERROR_BLUETOOTH_DISABLED,
                "ERROR_BLUETOOTH_GATT" to NokeMobileError.ERROR_BLUETOOTH_GATT,
                "DEVICE_ERROR_INVALID_KEY" to NokeMobileError.DEVICE_ERROR_INVALID_KEY
        )
    }

    @ReactMethod
    fun initService() {
        val nokeServiceIntent = Intent(reactApplicationContext, NokeDeviceManagerService::class.java)
        reactApplicationContext.bindService(nokeServiceIntent, mServiceConnection, Context.BIND_AUTO_CREATE)
    }

    @ReactMethod
    fun unlock(commands: ReadableArray, promise: Promise) {
        if (currentNoke == null) {
            promise.reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE)
            return
        } else {
            for (i in 0 until commands.size()) {
                currentNoke!!.sendCommands(commands.getString(i))
            }
            promise.resolve(nokeDeviceInfo(currentNoke))
        }
    }

    @ReactMethod
    fun unlockOffline(key: String, command: String, promise: Promise) {
        if (currentNoke == null) {
            promise.reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE)
            return
        }

        if (currentNoke!!.session == null) {
            promise.reject(RNNokeError.NO_LOCK_SESSION, RNNokeError.NO_LOCK_SESSION_MESSAGE)
            return
        }

        currentNoke!!.offlineKey = key
        currentNoke!!.offlineUnlockCmd = command
        currentNoke!!.offlineUnlock()
        promise.resolve(nokeDeviceInfo(currentNoke))
    }

    @ReactMethod
    fun changeLock(mac: String, promise: Promise) {
        val noke = NokeDevice(mac, mac)
        if (currentNoke != null) {
            mNokeService!!.disconnectNoke(this.currentNoke!!)
            mNokeService!!.startScanningForNokeDevices()
        }
        mNokeService!!.removeAllNoke()
        mNokeService!!.addNokeDevice(noke)
        currentNoke = noke
        promise.resolve(nokeDeviceInfo(noke))
    }

    @ReactMethod
    fun removeAllLock() {
        mNokeService!!.removeAllNoke()
        mNokeService!!.stopScanning()
    }

    @ReactMethod
    fun startScan() {
        mNokeService!!.startScanningForNokeDevices()
    }

    @ReactMethod
    fun stopScan() {
        mNokeService!!.stopScanning()
    }

    @ReactMethod
    fun disconnect() {
        if(currentNoke != null) {
            mNokeService!!.disconnectNoke(currentNoke)
        }
    }

    @ReactMethod
    fun deviceInfo(promise: Promise) {
        if (currentNoke == null) {
            promise.reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE)
        } else {
            promise.resolve(nokeDeviceInfo(currentNoke))
        }
    }

    private fun nokeDeviceInfo(noke: NokeDevice?): WritableMap {
        return if (noke == null) {
            writableMapOf()
        } else {
            writableMapOf(
                    "battery" to noke.battery?.toString(),
                    "connectionState" to noke.connectionState.toString(),
                    "offlineKey" to noke.offlineKey,
                    "lastSeen" to noke.lastSeen.toString(),
                    "lockState" to noke.lockState.toString(),
                    "mac" to noke.mac,
                    "name" to noke.name,
                    "serial" to noke.serial,
                    "session" to noke.session,
                    "trackingKey" to noke.trackingKey?.toString(),
                    "version" to noke.version
//                    "hardwareVersion" to noke.hardwareVersion?.toString(),
//                    "softwareVersion" to noke.softwareVersion?.toString(),
            )
        }
    }

    companion object {
        const val REACT_CLASS = "RNNoke"
        private var reactContext: ReactApplicationContext? = null

        private fun emitDeviceEvent(eventName: String, eventData: WritableMap?) {
            // A method for emitting from the native side to JS
            // https://facebook.github.io/react-native/docs/native-modules-android.html#sending-events-to-javascript
            reactContext!!.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java).emit(eventName, eventData)
        }
    }
}
