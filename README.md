
# react-native-noke

## Getting started

`$ npm install react-native-noke --save`

or

`$ yarn add react-native-noke`

or latest version

`$ yarn add git+git+https://github.com/Ant-Tech-Agency/react-native-noke.git`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-noke` and add `RNNoke.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNNoke.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<
5. Add empty file Test.swift in main project

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.lynkxyz.noke.RNNokePackage;` to the imports at the top of the file
  - Add `new RNNokePackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
    ```
    include ':react-native-noke'
    project(':react-native-noke').projectDir = new File(rootProject.projectDir,   '../node_modules/react-native-noke/android')
    ```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
    ```
      compile project(':react-native-noke')
    ```
4. After adding the dependency to your Android Manifest
  ```
  <service android:name="com.noke.nokemobilelibrary.NokeDeviceManagerService" android:enabled="true"/>
  ```


## Usage
```javascript
import RNNoke from 'react-native-noke';
RNNoke.initiateNokeService()

interface NokeData {
  name?: string
  key?: string
  command?: string
  macAddress: string
}

interface NokeCommandsData {
  macAddress: string  
  commands: string[]
}

interface NokeResponse {
  name: string,
  mac: string,
  session: string,
  status: boolean,
}

interface NokeInfoResponse {
  name: string,
  battery: number,
  mac: string,
  offlineKey: string,
  offlineUnlockCmd: string,
  serial: string,
  session: string,
  trackingKey: string,
  lastSeen: number,
  version: string,
}

type EventName = 
  'onServiceConnected' | // only Android
  'onServiceDisconnected' | // only Android
  'onNokeDiscovered' |
  'onNokeConnecting' |
  'onNokeConnected' |
  'onNokeSyncing' |
  'onNokeUnlocked' |
  'onNokeDisconnected' |
  'onBluetoothStatusChanged' |
  'onError'
  
interface RNNoke {
  initiateNokeService: () => Promise<{status: boolean}>
  startScan: () => Promise<{status: boolean}>
  stopScan: () => Promise<{status: boolean}>
  addNokeDeviceOnce: (data: NokeData) => Promise<NokeResponse>
  sendCommands: (data: NokeCommandsData) => Promise<NokeResponse>
  removeAllNokes: () => Promise<null>
  removeNokeDevice: () => Promise<null>
  offlineUnlock: (data: NokeData) => Promise<NokeResponse>
  getDeviceInfo: () => Promise<NokeInfoResponse>
  disconnect: () => Promise<null>
  on: (eventName: EventName, callback: (response: NokeResponse) => void) => RNNoke
  fromNokeEvents: () => Observable<{name: EventName, data: NokeResponse}>
}

export class App extends Component {
  componentDidMount() {
    this.requestLocationPermission() // only Android

    RNNoke
    .on('onServiceConnected', data => console.log('onServiceConnected', data)) // only Android 
    .on('onServiceDisconnected', data => console.log('onServiceConnected', data)) // only Android
    .on('onNokeDiscovered', data => console.log('onNokeDiscovered', data)) 
    .on('onNokeConnecting', data => console.log('onNokeConnecting', data))
    .on('onNokeConnected', data => console.log('onNokeConnected', data))
    .on('onNokeSyncing', data => console.log('onNokeSyncing', data))
    .on('onNokeUnlocked', data => console.log('onNokeUnlocked', data))
    .on('onNokeDisconnected', data => console.log('onNokeDisconnected', data))
    .on('onBluetoothStatusChanged', data => console.log('onBluetoothStatusChanged', data))
    .on('onError', data => console.log('onError', data))
  }

  requestLocationPermission = () => {
    if(Platform.OS === 'ios') return

    return PermissionsAndroid.request(
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
      {
        'title': 'Cool Location Permission',
        'message': 'Cool Location App needs access to your location '
      }
    )
    .then(console.log)
    .catch(console.error)
  }

  onUnlock = () => {
    RNNoke.offlineUnlock(data)
    .then(console.log)
    .catch(console.error)
  }

  onAddNoke = () => {
    RNNoke.addNokeDeviceOnce(data)
    .then(console.log)
    .catch(console.error)
  }

  onSendCommands = () => {
    RNNoke.sendCommands(data)
    .then(console.log)
    .catch(console.error)
  }

  onRemoveAllNokes = () => {
    RNNoke.removeAllNokes()
    .then(console.log)
    .catch(console.error)
  }
  
  getDeviceInfo = () => {
    RNNoke.getDeviceInfo()
    .then(console.log)
    .catch(console.error)
  }
  
  onStartScan = () => {
    RNNoke.startScan()
    .then(console.log)
    .catch(console.error)
  }
    
  onStopScan = () => {
    RNNoke.stopScan()
    .then(console.log)
    .catch(console.error)
  }

  render() {
    return (
      <View style={styles.container}>
        <Button
          onPress={this.onSendCommands}
          title="Unlock noke by commands"
        />

        <Button
          onPress={this.onUnlock}
          title="Unlock noke offline"
        />

        <Button
          onPress={this.onAddNoke}
          title="Add noke"
        />

        <Button
          onPress={this.onRemoveAllNokes}
          title="Remove noke"
        />
      </View>
    )
  }
}
```

## License

react-native-noke is available under the Apache 2.0 license. See the LICENSE file for more info.

Copyright © 2018 Ant-Tech Ltd. All rights reserved.
