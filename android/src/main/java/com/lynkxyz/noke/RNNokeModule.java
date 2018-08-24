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
import com.noke.nokemobilelibrary.NokeDevice;
import com.noke.nokemobilelibrary.NokeDeviceManagerService;
import com.noke.nokemobilelibrary.NokeMobileError;
import com.noke.nokemobilelibrary.NokeServiceListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.IllformedLocaleException;
import java.util.List;
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
    event.putString("session", nokeDevice.getSession());
    event.putBoolean("status", true);

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

  private void addOfflineData(NokeDevice noke, ReadableMap data) {
    if (data.hasKey("key") && data.hasKey("command")) {
      noke.setOfflineKey(data.getString("key"));
      noke.setOfflineUnlockCmd(data.getString("command"));
    }
  }

  private NokeDevice getCurrentNoke(ReadableMap data) {
    String macAddress = data.hasKey("macAddress") ? data.getString("macAddress") : "";
    String name = data.hasKey("name") ? data.getString("name") : "";

    NokeDevice currentNoke = null;
    ArrayList<NokeDevice> nokeDeviceArrayList = mNokeService.getAllNoke();
    for(int i = 0; i < nokeDeviceArrayList.size(); i++) {
      NokeDevice _currentNoke = nokeDeviceArrayList.get(i);
      Boolean isMacEquals = _currentNoke.getMac().equals(macAddress);

      if(isMacEquals) {
        currentNoke = _currentNoke;
      }
    }

    if(currentNoke == null) {
      NokeDevice nokeDevice = new NokeDevice(
              name,
              macAddress
      );
      currentNoke = nokeDevice;
      mNokeService.connectToNoke(nokeDevice);
    }

    return currentNoke;
  }

  private HashMap<String, String> getValuesFromData(ReadableMap data) {
    String macAddress = data.hasKey("macAddress") ? data.getString("macAddress") : "";
    String name = data.hasKey("name") ? data.getString("name") : "";
    String key = data.hasKey("key") ? data.getString("key") : null;
    String command = data.hasKey("command") ? data.getString("command") : null;

    HashMap<String, String> hashMap = new HashMap<>();
    hashMap.put("macAddress", macAddress);
    hashMap.put("name", name);
    hashMap.put("key", key);
    hashMap.put("command", command);

    return hashMap;
  }

  @ReactMethod
  public void addNokeDeviceOnce(ReadableMap data, Promise promise) {
    HashMap<String, String> values = getValuesFromData(data);
    String macAddress = values.get("macAddress");
    String name = values.get("name");
    String key = values.get("key");
    String command = values.get("command");

    Integer flag = 0;
    NokeDevice selectedNoke = null;
    currentNoke = null;

    ArrayList<NokeDevice> nokeDeviceArrayList = mNokeService.getAllNoke();
    for(int i = 0; i < nokeDeviceArrayList.size(); i++) {
      NokeDevice _currentNoke = nokeDeviceArrayList.get(i);
      Boolean isMacEquals = _currentNoke.getMac().equals(macAddress);

      if(!isMacEquals) {
        flag++;
        mNokeService.disconnectNoke(_currentNoke);
      } else {
        selectedNoke = _currentNoke;
      }
    }

    if(selectedNoke != null) {
      if(key != null && command != null) {
        selectedNoke.setOfflineKey(key);
        selectedNoke.setOfflineUnlockCmd(command);
      }
      currentNoke = selectedNoke;
      mNokeService.connectToNoke(selectedNoke);
    }

    if(flag == nokeDeviceArrayList.size()) {
      NokeDevice nokeDevice = new NokeDevice(
              name,
              macAddress
      );
      if(key != null && command != null) {
        nokeDevice.setOfflineKey(key);
        nokeDevice.setOfflineUnlockCmd(command);
      }
      mNokeService.addNokeDevice(nokeDevice);
      selectedNoke = nokeDevice;
      currentNoke = selectedNoke;
    }

    promise.resolve(createCommonEvents(selectedNoke));
  }

  @ReactMethod
  public void sendCommands(ReadableMap data, Promise promise) {
    ReadableArray commands = data.hasKey("commands") ? data.getArray("commands") : null;
    NokeDevice nokeDevice = getCurrentNoke(data);

    if(commands != null) {
      ArrayList<Object> commandsArray = commands.toArrayList();
      for (int i = 0; i < commandsArray.size(); i++) {
        nokeDevice.sendCommands(commandsArray.get(i).toString());
      }
    }

    promise.resolve(createCommonEvents(currentNoke));
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

      if (data.hasKey("key") && data.hasKey("cmd")) {
        noke.setOfflineKey(data.getString("key"));
        noke.setOfflineUnlockCmd(data.getString("cmd"));
      }

      if (mNokeService == null) {
        promise.reject("message", "mNokeService is null");
        return;
      }
      mNokeService.addNokeDevice(noke);

      promise.resolve(createCommonEvents(noke));
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
  }

  @ReactMethod
  public void setOfflineData(ReadableMap data, Promise promise) {
    try {
      if (mNokeService == null) {
        promise.reject("message", "mNokeService is null");
        return;
      }

      if(currentNoke == null && data.hasKey("name") && data.hasKey("mac")) {
        if (!data.hasKey("name") || !data.hasKey("mac")) {
          promise.reject("message", "Missing name or mac attributes");
          return;
        }

        currentNoke = new NokeDevice(
                data.getString("name"),
                data.getString("mac")
        );
      }

      if (data.hasKey("key") && data.hasKey("cmd")) {
        currentNoke.setOfflineKey(data.getString("key"));
        currentNoke.setOfflineUnlockCmd(data.getString("cmd"));
      } else {
          promise.reject("message", "Missing key or command attributes");
          return;
      }

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
      Log.e("disconnect", "currentNoke is null");
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
      mNokeService.removeNokeDevice(mac);

      final WritableMap event = Arguments.createMap();
      event.putBoolean("status", true);

      promise.resolve(event);
  }

  @ReactMethod
  public void offlineUnlock(ReadableMap data, Promise promise) {
    NokeDevice nokeDevice = getCurrentNoke(data);
    WritableMap event = createCommonEvents(nokeDevice);

    if (nokeDevice.getOfflineUnlockCmd() != null){
      event.putBoolean("success", true);

      nokeDevice.offlineUnlock();
    }
    promise.resolve(event);
  }

  @ReactMethod
  public void getDeviceInfo(Promise promise) {
    try {
      WritableMap event = Arguments.createMap();

      if (currentNoke == null) {
        event.putBoolean("success", false);
      } else {
        event.putBoolean("success", true);
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
    } catch (IllegalViewOperationException e) {
      promise.reject("message", e.getMessage());
    }
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
      Log.w(TAG, "ON SERVICE CONNECTED");
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
//      mNokeService.stopScanning();
//      currentNoke = noke;
      mNokeService.connectToNoke(noke);
      emitDeviceEvent("onNokeDiscovered", createCommonEvents(noke));
    }

    @Override
    public void onNokeConnecting(NokeDevice noke) {
//      currentNoke = noke;
      emitDeviceEvent("onNokeConnecting", createCommonEvents(noke));
    }

    @Override
    public void onNokeConnected(NokeDevice noke) {
      currentNoke = noke;
      emitDeviceEvent("onNokeConnected", createCommonEvents(noke));
      mNokeService.stopScanning();
    }

    @Override
    public void onNokeSyncing(NokeDevice noke) {
      emitDeviceEvent("onNokeSyncing", createCommonEvents(noke));
    }

    @Override
    public void onNokeUnlocked(NokeDevice noke) {
      emitDeviceEvent("onNokeUnlocked", createCommonEvents(noke));
    }

    @Override
    public void onNokeDisconnected(NokeDevice noke) {
      emitDeviceEvent("onNokeDisconnected", createCommonEvents(noke));
      currentNoke = null;
      mNokeService.stopScanning();
//      mNokeService.uploadData();
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
//        case NokeMobileError.ERROR_LOCATION_PERMISSIONS_NEEDED:
//          return;
//        case NokeMobileError.ERROR_LOCATION_SERVICES_DISABLED:
//          return;
//        case NokeMobileError.ERROR_BLUETOOTH_DISABLED:
//          return;
//        case NokeMobileError.ERROR_BLUETOOTH_GATT:
//          return;
        case NokeMobileError.DEVICE_ERROR_INVALID_KEY:
          return;
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