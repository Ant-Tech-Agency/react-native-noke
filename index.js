import {
  NativeEventEmitter,
  NativeModules
} from 'react-native'
import {
  addNokeDeviceIfNeeded,
  fromNokeEvents,
  onEvent
} from './events'

const { RNNoke } = NativeModules

export default {
  initiateNokeService: RNNoke.initiateNokeService,
  on: onEvent,
  offlineUnlock: RNNoke.offlineUnlock,
  sendCommands: RNNoke.sendCommands,
  addNokeDevice: RNNoke.addNokeDevice,
  removeAllNokes: RNNoke.removeAllNokes,
  removeNokeDevice: RNNoke.removeNokeDevice,
  startScan: RNNoke.startScan,
  stopScan: RNNoke.stopScan,
  disconnect: RNNoke.disconnect,
  getDeviceInfo: RNNoke.getDeviceInfo,
  setOfflineData: RNNoke.setOfflineData,
  fromNokeEvents,
  addNokeDeviceIfNeeded,

  AUTHOR: RNNoke.AUTHOR
}