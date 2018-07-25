
# react-native-noke

## Getting started

`$ npm install react-native-noke --save`
`$ yarn add react-native-noke`

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
  	project(':react-native-noke').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-noke/android')
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

export default class App extends Component<Props> {
	componentDidMount() {
		this.requestLocationPermission() // only Android

		RNNoke.initiateNokeService()
		.then(noke => {
			console.log('noke', noke)

			RNNoke
			.on('onServiceConnected', data => console.log('onServiceConnected', data))
			.on('onNokeDiscovered', data => console.log('onNokeDiscovered', data))
			.on('onNokeConnecting', data => console.log('onNokeConnecting', data))
			.on('onNokeConnected', data => console.log('onNokeConnected', data))
			.on('onNokeSyncing', data => console.log('onNokeSyncing', data))
			.on('onNokeUnlocked', data => console.log('onNokeUnlocked', data))
			.on('onNokeDisconnected', data => console.log('onNokeDisconnected', data))
			.on('onBluetoothStatusChanged', data => console.log('onBluetoothStatusChanged', data))
			.on('onError', data => console.log('onError', data))
		})
	}

	requestLocationPermission = () => {
		if(Platform.OS === 'ios') return

		return PermissionsAndroid.request(
			PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
			{
				'title': 'Cool Photo App Camera Permission',
				'message': 'Cool Photo App needs access to your camera ' +
				'so you can take awesome pictures.'
			}
		)
		.then(console.log)
		.catch(console.error)
	}

	onUnlock = () => {
		RNNoke.offlineUnlock()
		.then(console.log)
		.catch(console.error)
	}

	onAddNoke = () => {
		RNNoke.addNokeDevice({
			name: 'LinhNoke',
			mac: "CB:BC:87:3B:CB:D7",
			key: "9966eb079eabb129e7adbded88eab6c3",
			cmd: "0152843f00a2dec3515b000000000000000000ef"
		})
		.then(console.log)
		.catch(console.error)
	}

	onSendCommands = () => {
		RNNoke.sendCommands("0152843f00a2dec3515b000000000000000000ef")
		.then(console.log)
		.catch(console.error)
	}

	onRemoveAllNokes = () => {
		RNNoke.removeAllNokes()
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
  