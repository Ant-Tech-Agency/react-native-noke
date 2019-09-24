package com.lynkxyz.noke

import android.bluetooth.BluetoothAdapter
import android.content.Context.BIND_AUTO_CREATE
import com.noke.nokemobilelibrary.NokeDeviceManagerService
import android.content.Intent
import android.content.ComponentName
import android.os.IBinder
import android.content.ServiceConnection
import android.util.Log
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.noke.nokemobilelibrary.NokeDefines
import com.noke.nokemobilelibrary.NokeDevice
import com.noke.nokemobilelibrary.NokeServiceListener

class NokeModule(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private var mNokeService: NokeDeviceManagerService? = null
    private var currentNoke: NokeDevice? = null
    private var isConnected = false

    private fun emitDeviceEvent(eventName: String, eventData: WritableMap?) {
        // A method for emitting from the native side to JS
        // https://facebook.github.io/react-native/docs/native-modules-android.html#sending-events-to-javascript
        reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java).emit(eventName, eventData)
    }

    override fun getName(): String {
        return "Noke"
    }

    @ReactMethod
    private fun isInitialized(promise: Promise) {
        if (mNokeService != null) {
            promise.resolve(true)
        } else {
            promise.resolve(false)
        }
    }

    @ReactMethod
    private fun initService() {
        val nokeServiceIntent = Intent(reactContext, NokeDeviceManagerService::class.java)
        reactContext.bindService(nokeServiceIntent, mServiceConnection, BIND_AUTO_CREATE)
    }

    @ReactMethod
    fun unlock(commands: ReadableArray, promise: Promise) {
        try {
            if (currentNoke == null) {
                promise.reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE)
                return
            }

            for (i in 0 until commands.size()) {
                currentNoke!!.sendCommands(commands.getString(i))
            }
            promise.resolve(nokeDeviceInfoFactory(currentNoke))
        } catch (e: Throwable) {
            Log.d("Error", e.toString())
        }
    }

    @ReactMethod
    fun unlockOffline(key: String, command: String, promise: Promise) {
        try {
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
            promise.resolve(nokeDeviceInfoFactory(currentNoke))
        } catch (e: Throwable) {
            Log.d("Error", e.toString())
        }
    }

    @ReactMethod
    fun change(mac: String, promise: Promise) {
        val noke = NokeDevice(mac, mac)
        if (currentNoke != null) {
            mNokeService!!.disconnectNoke(this.currentNoke!!)
        }
        isConnected = false
        mNokeService!!.removeAllNoke()
        mNokeService!!.addNokeDevice(noke)
        mNokeService!!.startScanningForNokeDevices()
        currentNoke = noke
        promise.resolve(nokeDeviceInfoFactory(noke))
    }

    @ReactMethod
    fun removeAll() {
        isConnected = false
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
    fun disconnectCurrent() {
        if (currentNoke != null) {
            mNokeService!!.disconnectNoke(currentNoke)
        }
    }

    @ReactMethod
    fun getDeviceInfo(promise: Promise) {
        if (currentNoke == null) {
            promise.reject(RNNokeError.NO_LOCK_CONNECTED, RNNokeError.NO_LOCK_CONNECTED_MESSAGE)
        } else {
            promise.resolve(nokeDeviceInfoFactory(currentNoke))
        }
    }

    private val mServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(className: ComponentName, rawBinder: IBinder) {

            //Store reference to service
            mNokeService = (rawBinder as NokeDeviceManagerService.LocalBinder).getService(NokeDefines.NOKE_LIBRARY_SANDBOX)

            //Register callback listener
            mNokeService!!.registerNokeListener(mNokeServiceListener)

            //Start bluetooth scanning
            mNokeService!!.startScanningForNokeDevices()

            emitDeviceEvent("ServiceConnected", writableMapOf(
                    "connected" to mNokeService!!.initialize()
            ))
        }

        override fun onServiceDisconnected(classname: ComponentName) {
            mNokeService = null

            emitDeviceEvent("ServiceDisconnected", writableMapOf(
                    "connected" to false
            ))
        }
    }

    private val mNokeServiceListener = object : NokeServiceListener {
        override fun onNokeDiscovered(noke: NokeDevice) {
            if(!isConnected) {
                currentNoke = noke
                mNokeService!!.connectToNoke(currentNoke)
                emitDeviceEvent("Discovered", nokeDeviceInfoFactory(noke))
                isConnected = true
            }
        }

        override fun onNokeConnecting(noke: NokeDevice) {
            emitDeviceEvent("Connecting", nokeDeviceInfoFactory(noke))
        }

        override fun onNokeConnected(noke: NokeDevice) {
            currentNoke = noke
            mNokeService!!.stopScanning()
            emitDeviceEvent("Connected", nokeDeviceInfoFactory(noke))
        }

        override fun onNokeSyncing(noke: NokeDevice) {
            emitDeviceEvent("Syncing", nokeDeviceInfoFactory(noke))
        }

        override fun onNokeUnlocked(noke: NokeDevice) {
            emitDeviceEvent("Unlocked", nokeDeviceInfoFactory(noke))
        }

        override fun onNokeShutdown(noke: NokeDevice, isLocked: Boolean?, didTimeout: Boolean?) {
            isConnected = false
            emitDeviceEvent("Shutdown", writableMapOf(
                    "noke" to nokeDeviceInfoFactory(noke),
                    "isLocked" to isLocked,
                    "didTimeout" to didTimeout
            ))
        }

        override fun onNokeDisconnected(noke: NokeDevice) {
            isConnected = false
            currentNoke = null
            //mNokeService.uploadData();
            mNokeService!!.startScanningForNokeDevices()
            mNokeService!!.setBluetoothScanDuration(8000)
            emitDeviceEvent("Disconnected", writableMapOf(
                    "noke" to nokeDeviceInfoFactory(noke)
            ))
        }

        override fun onDataUploaded(result: Int, message: String) {
            emitDeviceEvent("Uploaded", writableMapOf(
                    "result" to result,
                    "message" to message
            ))
        }

        override fun onBluetoothStatusChanged(bluetoothStatus: Int) {
            when (bluetoothStatus) {
                BluetoothAdapter.STATE_ON -> startScan()
            }
            emitDeviceEvent("BluetoothStatusChanged", writableMapOf(
                    "status" to bluetoothStatus
            ))
        }

        override fun onError(noke: NokeDevice?, error: Int, message: String) {
            emitDeviceEvent("Error", writableMapOf(
                    "noke" to nokeDeviceInfoFactory(noke),
                    "message" to message,
                    "error" to error
            ))
        }
    }

    private fun nokeDeviceInfoFactory(noke: NokeDevice?): WritableMap {
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
            )
        }
    }
}
