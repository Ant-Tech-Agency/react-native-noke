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
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import com.facebook.react.uimanager.IllegalViewOperationException;
import com.noke.nokemobilelibrary.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.IllformedLocaleException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class RNNokeModule extends ReactContextBaseJavaModule {
  public static final String REACT_CLASS = "RNNoke";
  private static ReactApplicationContext reactContext = null;

  public static final String TAG = "RNNoke";
  private NokeDeviceManagerService mNokeService = null;
  private NokeDevice currentNoke;
  private int lastEventCode = -1;

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
    event.putString("session", nokeDevice.getSession());
    event.putBoolean("status", true);

    return event;
  }

  @ReactMethod
  private void initiateNokeService(Promise promise) {
    try {
      Intent nokeServiceIntent = new Intent(reactContext, NokeDeviceManagerService.class);
      getReactApplicationContext().bindService(nokeServiceIntent, mServiceConnection, Context.BIND_AUTO_CREATE);
//      mNokeService.setUploadUrl("https://v1.api.nokepro.com/lock/upload/");

      WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void startScan(Promise promise) {
    mNokeService.startScanningForNokeDevices();
    final WritableMap event = Arguments.createMap();
    event.putBoolean("status", true);

    promise.resolve(event);
  }

  @ReactMethod
  public void stopScan(Promise promise) {
    mNokeService.stopScanning();
    final WritableMap event = Arguments.createMap();
    event.putBoolean("status", true);

    promise.resolve(event);
  }

  private NokeDevice getCurrentNoke(String macAddress) {
    if(mNokeService != null) {
      LinkedHashMap<String, NokeDevice> nokeDevices = mNokeService.nokeDevices;

      return nokeDevices.get(macAddress);
    }

    return null;
  }

  private NokeDevice addNokeIfNeeded(NokeHashMap nokeHashMap) {
    String name = nokeHashMap.getName();
    String key = nokeHashMap.getKey();
    String command = nokeHashMap.getCommand();
    String macAddress = nokeHashMap.getMacAddress();

    NokeDevice nokeDevice = getCurrentNoke(macAddress);

    if(mNokeService == null) {
      return null;
    }

    if(nokeDevice == null) {
      nokeDevice = new NokeDevice(
              name,
              macAddress
      );
      mNokeService.addNokeDevice(nokeDevice);
    }

    if(nokeDevice.getOfflineUnlockCmd() == null) {
      if(key != null && command != null) {
        nokeDevice.setOfflineUnlockCmd(command);
        nokeDevice.setOfflineKey(key);
      }
    }

    currentNoke = nokeDevice;

    return nokeDevice;
  }

  @ReactMethod
  public void addNokeDevice(ReadableMap data, Promise promise) {
    NokeHashMap nokeHashMap = new NokeHashMap(data);

    NokeDevice nokeDevice = addNokeIfNeeded(nokeHashMap);

    if(nokeDevice == null) {
      promise.reject("300", "Can't get or add nokeDevice");
      return;
    }

    promise.resolve(createCommonEvents(nokeDevice));
  }

  @ReactMethod
  public void addNokeDeviceOnce(ReadableMap data, Promise promise) {
    NokeHashMap nokeHashMap = new NokeHashMap(data);
    String macAddress = nokeHashMap.getMacAddress();

    if(currentNoke != null && !currentNoke.getMac().equals(macAddress)) {
      mNokeService.removeNokeDevice(macAddress);
    }

    NokeDevice nokeDevice = addNokeIfNeeded(nokeHashMap);

    if(nokeDevice == null) {
      promise.reject("300", "Can't get or add nokeDevice");
      return;
    }

    promise.resolve(createCommonEvents(nokeDevice));
  }

  @ReactMethod
  public void sendCommands(ReadableMap data, Promise promise) {
    NokeHashMap nokeHashMap = new NokeHashMap(data);
    String macAddress = nokeHashMap.getMacAddress();
    ArrayList<String> commands = nokeHashMap.getCommands();
    NokeDevice nokeDevice = getCurrentNoke(macAddress);

    if(nokeDevice == null) {
      promise.reject("100", "Noke device is null");
      return;
    }

    if(commands != null) {
      for (int i = 0; i < commands.size(); i++) {
        nokeDevice.sendCommands(commands.get(i));
      }
    }

    promise.resolve(createCommonEvents(nokeDevice));
  }

  @ReactMethod
  public void removeAllNokes(Promise promise) {
    mNokeService.removeAllNoke();
    promise.resolve(null);
  }

  @ReactMethod
  public void removeNokeDevice(String mac, Promise promise) {
    mNokeService.removeNokeDevice(mac);

    promise.resolve(null);
  }

  @ReactMethod
  public void offlineUnlock(ReadableMap data, Promise promise) {
    NokeHashMap nokeHashMap = new NokeHashMap(data);
    String macAddress = nokeHashMap.getMacAddress();
    NokeDevice nokeDevice = getCurrentNoke(macAddress);

    if(nokeDevice == null) {
      promise.reject("100", "Noke device is null");
      return;
    }

    WritableMap event = createCommonEvents(nokeDevice);
    if(lastEventCode == 4) {
      promise.resolve(event);
      return;
    }

    if (nokeDevice.getOfflineUnlockCmd() != null){
      nokeDevice.offlineUnlock();
    }
    promise.resolve(event);
  }

  @ReactMethod
  public void getDeviceInfo(Promise promise) {
    WritableMap event = Arguments.createMap();

    if (currentNoke == null) {
      event.putBoolean("status", false);
    } else {
      event.putBoolean("status", true);
      event.putString("name", currentNoke.getName());
      event.putInt("battery", currentNoke.getBattery());
      event.putString("mac", currentNoke.getMac());
      event.putString("offlineKey", currentNoke.getOfflineKey());
      event.putString("offlineUnlockCmd", currentNoke.getOfflineUnlockCmd());
      event.putString("serial", currentNoke.getSerial());
      event.putString("session", currentNoke.getSession());
      event.putString("trackingKey", currentNoke.getTrackingKey());
      event.putDouble("lastSeen", currentNoke.getLastSeen());
      event.putString("version", currentNoke.getVersion());
    }

    promise.resolve(event);
  }

  @ReactMethod
  public void setAPIKey(String apiKey, Promise promise) {
    mNokeService.setApiKey(apiKey);

    promise.resolve(null);
  }

  @Override
  public String getName() {
    return REACT_CLASS;
  }

  @Override
  public Map<String, Object> getConstants() {
    final Map<String, Object> constants = new HashMap<>();
    constants.put("AUTHOR", "linh_the_human");

    return constants;
  }

  private ServiceConnection mServiceConnection = new ServiceConnection() {
    public void onServiceConnected(ComponentName className, IBinder rawBinder) {
      Log.d("CONNECT", "ON SERVICE CONNECTED");
      mNokeService = ((NokeDeviceManagerService.LocalBinder) rawBinder).getService();
      mNokeService.registerNokeListener(mNokeServiceListener);
      String message = "On service connected";

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
      mNokeService.stopScanning();
      if(currentNoke.getMac().equals(noke.getMac())) {
        mNokeService.connectToNoke(noke);
      }
      lastEventCode = 0;
      emitDeviceEvent("onNokeDiscovered", createCommonEvents(noke));
    }

    @Override
    public void onNokeConnecting(NokeDevice noke) {
      emitDeviceEvent("onNokeConnecting", createCommonEvents(noke));
      lastEventCode = 1;
    }

    @Override
    public void onNokeConnected(NokeDevice noke) {
      emitDeviceEvent("onNokeConnected", createCommonEvents(noke));
      lastEventCode = 2;
    }

    @Override
    public void onNokeSyncing(NokeDevice noke) {
      emitDeviceEvent("onNokeSyncing", createCommonEvents(noke));
      lastEventCode = 3;
    }

    @Override
    public void onNokeUnlocked(NokeDevice noke) {
      emitDeviceEvent("onNokeUnlocked", createCommonEvents(noke));
      lastEventCode = 4;
    }

    @Override
    public void onNokeDisconnected(NokeDevice noke) {
      emitDeviceEvent("onNokeDisconnected", createCommonEvents(noke));
      mNokeService.stopScanning();
      lastEventCode = 5;
      mNokeService.uploadData();
    }

    @Override
    public void onDataUploaded(int i, String s) {
        Log.d("UPLOADED", s);
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
//      switch (error) {
//        case NokeMobileError.DEVICE_ERROR_INVALID_KEY:
//          return;
//      }
      final WritableMap event = Arguments.createMap();
      event.putInt("code", error);
      event.putString("message", message);
      lastEventCode = 6;
      emitDeviceEvent("onError", event);
    }
  };

  private static void emitDeviceEvent(String eventName, @Nullable WritableMap eventData) {
    // A method for emitting from the native side to JS
    // https://facebook.github.io/react-native/docs/native-modules-android.html#sending-events-to-javascript
    reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, eventData);
  }
}