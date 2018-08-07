import {
	NativeModules,
	NativeEventEmitter,
} from 'react-native'

const {RNNoke} = NativeModules
const NokeEmitter = new NativeEventEmitter(RNNoke)

export default {
	initiateNokeService: RNNoke.initiateNokeService,
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
  stopScan: RNNoke.stopScan,
  disconnect: RNNoke.disconnect,

	AUTHOR: RNNoke.AUTHOR
}