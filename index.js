import {
	NativeModules,
	NativeEventEmitter,
	Platform
} from 'react-native'

const {RNNoke} = NativeModules
const NokeEmitter = new NativeEventEmitter(RNNoke)

export default {
	initiateNokeService() {
		return RNNoke.initiateNokeService()
	},
	on(eventName, callback) {
		NokeEmitter.addListener(eventName, callback)
		return this
	},
	offlineUnlock: RNNoke.offlineUnlock,
	sendCommands: RNNoke.sendCommands,
	addNokeDevice: RNNoke.addNokeDevice,
	removeAllNokes: RNNoke.removeAllNokes,
	removeNokeDevice: RNNoke.removeNokeDevice,
	startScan: RNNoke.startScan,

	AUTHOR: RNNoke.AUTHOR
}