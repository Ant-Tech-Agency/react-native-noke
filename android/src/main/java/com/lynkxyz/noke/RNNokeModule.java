package com.lynkxyz.noke;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.support.annotation.Nullable;
import android.system.ErrnoException;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import com.facebook.react.uimanager.IllegalViewOperationException;
import com.noke.nokemobilelibrary.NokeDevice;
import com.noke.nokemobilelibrary.NokeDeviceManagerService;
import com.noke.nokemobilelibrary.NokeMobileError;
import com.noke.nokemobilelibrary.NokeServiceListener;

import java.util.HashMap;
import java.util.IllformedLocaleException;
import java.util.Map;

public class RNNokeModule extends ReactContextBaseJavaModule {
  public static final String REACT_CLASS = "RNNoke";
  private static ReactApplicationContext reactContext = null;

  public static final String TAG = "RNNoke";
  private NokeDeviceManagerService mNokeService = null;
  private NokeDevice currentNoke;

  public RNNokeModule(ReactApplicationContext context) {
    // Pass in the context to the constructor and save it so you can emit events
    // https://facebook.github.io/react-native/docs/native-modules-android.html#the-toast-module
    super(context);

    reactContext = context;
  }

  private WritableMap createCommonEvents(NokeDevice nokeDevice) {
    final WritableMap event = Arguments.createMap();

    if(nokeDevice == null) {
      return event;
    }

    event.putString("name", nokeDevice.getName());
    event.putString("mac", nokeDevice.getMac());

    return event;
  }

  @ReactMethod
  private void initiateNokeService(Promise promise) {
    try {
      Intent nokeServiceIntent = new Intent(reactContext, NokeDeviceManagerService.class);
      reactContext.bindService(nokeServiceIntent, mServiceConnection, Context.BIND_AUTO_CREATE);
      WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void startScan(Promise promise) {
    try {
      mNokeService.startScanningForNokeDevices();
      final WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void stopScan(Promise promise) {
    try {
      mNokeService.stopScanning();
      final WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void addNokeDevice(ReadableMap data, Promise promise) {
    try {
      /**
       * name: "Lock Name"
       * mac: "XX:XX:XX:XX:XX:XX"
       * key: "OFFLINE_KEY"
       * cmd: "OFFLINE_COMMAND"
       */
      if(data == null) {
        promise.reject("message", "data is null");
        return;
      }

      NokeDevice noke = new NokeDevice(
              data.getString("name"),
              data.getString("mac")
      );
      noke.setOfflineKey(data.getString("key"));
      noke.setOfflineUnlockCmd(data.getString("cmd"));

      if (mNokeService == null) {
        promise.reject("message", "mNokeService is null");
        return;
      }
      mNokeService.addNokeDevice(noke);

      final WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void sendCommands(String command, Promise promise) {
    try {
      if(currentNoke == null) {
        promise.reject("message", "currentNoke is null");
        return;
      }
      currentNoke.sendCommands(command);
      promise.resolve(createCommonEvents(currentNoke));
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void disconnect(Promise promise) {
    if(mNokeService == null) {
      promise.reject("message", "mNokeService is null");
      return;
    }
    if(currentNoke == null) {
      promise.reject("message", "currentNoke is null");
      return;
    }

    mNokeService.disconnectNoke(currentNoke);

    final WritableMap event = Arguments.createMap();
    event.putBoolean("status", true);
    promise.resolve(event);
  }

  @ReactMethod
  public void removeAllNokes(Promise promise) {
    try {
      mNokeService.removeAllNoke();
      final WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void removeNokeDevice(String mac, Promise promise) {
    try {
      mNokeService.removeNokeDevice(mac);

      final WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void offlineUnlock(Promise promise) {
    try {
      WritableMap event = createCommonEvents(currentNoke);

      if (currentNoke == null) {
        event.putBoolean("success", false);
      } else {
        event.putBoolean("success", true);
        currentNoke.offlineUnlock();
      }
      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @Override
  public String getName() {
    // Tell React the name of the module
    // https://facebook.github.io/react-native/docs/native-modules-android.html#the-toast-module
    return REACT_CLASS;
  }

  @Override
  public Map<String, Object> getConstants() {
    // Export any constants to be used in your native module
    // https://facebook.github.io/react-native/docs/native-modules-android.html#the-toast-module
    final Map<String, Object> constants = new HashMap<>();
    constants.put("AUTHOR", "linh_the_human");

    return constants;
  }

  private ServiceConnection mServiceConnection = new ServiceConnection() {

    public void onServiceConnected(ComponentName className, IBinder rawBinder) {
      final WritableMap initEvent = Arguments.createMap();
      initEvent.putString("message", "On service connected");
      initEvent.putBoolean("status", true);
      emitDeviceEvent("onServiceConnected", initEvent);

      Log.w(TAG, "ON SERVICE CONNECTED");

      //Store reference to service
      mNokeService = ((NokeDeviceManagerService.LocalBinder) rawBinder).getService();

      //Uncomment to allow devices that aren't in the device array
      //mNokeService.setAllowAllDevices(true);

      //Register callback listener
      mNokeService.registerNokeListener(mNokeServiceListener);

      //Add locks to device manager


            /*
            Sets the url to use for uploading responses from the lock to the API.  This is the only
            case where the mobile app should be making requests to the Noke Core API directly.
             */

      //mNokeService.setUploadUrl("UPLOAD URL HERE");

      //Start bluetooth scanning
      mNokeService.startScanningForNokeDevices();
      String message = "Scanning for Noke Devices";


      if (!mNokeService.initialize()) {
        Log.e(TAG, "Unable to initialize Bluetooth");
        message = "Unable to initialize Bluetooth";
      }
      final WritableMap event = Arguments.createMap();
      event.putString("message", message);
      event.putBoolean("status", true);
      emitDeviceEvent("onServiceConnected", event);
    }

    public void onServiceDisconnected(ComponentName classname) {
      mNokeService = null;
      final WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);
      emitDeviceEvent("onServiceDisconnected", event);
    }
  };

  private NokeServiceListener mNokeServiceListener = new NokeServiceListener() {
    @Override
    public void onNokeDiscovered(NokeDevice noke) {
      final WritableMap event = Arguments.createMap();
      event.putString("name", noke.getName());
      emitDeviceEvent("onNokeDiscovered", event);
      mNokeService.connectToNoke(noke);
    }

    @Override
    public void onNokeConnecting(NokeDevice noke) {
      final WritableMap event = Arguments.createMap();
      event.putString("name", noke.getName());
      emitDeviceEvent("onNokeConnecting", event);
    }

    @Override
    public void onNokeConnected(NokeDevice noke) {
      currentNoke = noke;
      final WritableMap event = Arguments.createMap();
      event.putString("name", noke.getName());
      emitDeviceEvent("onNokeConnected", event);
      mNokeService.stopScanning();
    }

    @Override
    public void onNokeSyncing(NokeDevice noke) {
      final WritableMap event = Arguments.createMap();
      event.putString("name", noke.getName());
      emitDeviceEvent("onNokeSyncing", event);
    }

    @Override
    public void onNokeUnlocked(NokeDevice noke) {
      final WritableMap event = Arguments.createMap();
      event.putString("name", noke.getName());
      emitDeviceEvent("onNokeUnlocked", event);
    }

    @Override
    public void onNokeDisconnected(NokeDevice noke) {
      final WritableMap event = Arguments.createMap();
      event.putString("name", noke.getName());
      emitDeviceEvent("onNokeDisconnected", event);
      currentNoke = null;
      mNokeService.uploadData();
//      mNokeService.startScanningForNokeDevices();
    }

    @Override
    public void onDataUploaded(int i, String s) {

    }

    @Override
    public void onBluetoothStatusChanged(int bluetoothStatus) {
      final WritableMap event = Arguments.createMap();
      event.putInt("code", bluetoothStatus);
      emitDeviceEvent("onBluetoothStatusChanged", event);
    }

    @Override
    public void onError(NokeDevice noke, int error, String message) {
      Log.e(TAG, "NOKE SERVICE ERROR " + error + ": " + message);
      switch (error) {
        case NokeMobileError.ERROR_LOCATION_PERMISSIONS_NEEDED:
          break;
        case NokeMobileError.ERROR_LOCATION_SERVICES_DISABLED:
          break;
        case NokeMobileError.ERROR_BLUETOOTH_DISABLED:
          break;
        case NokeMobileError.ERROR_BLUETOOTH_GATT:
          break;
      }
      final WritableMap event = Arguments.createMap();
      event.putInt("code", error);
      event.putString("message", message);
      emitDeviceEvent("onError", event);
    }
  };

  private static void emitDeviceEvent(String eventName, @Nullable WritableMap eventData) {
    // A method for emitting from the native side to JS
    // https://facebook.github.io/react-native/docs/native-modules-android.html#sending-events-to-javascript
    reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, eventData);
  }
}