import {
  NativeEventEmitter,
  NativeModules
} from 'react-native'
import {
  fromNokeEvents,
  onEvent
} from './events'
import {
  addNokeDeviceOnce$,
  createNokeOptions
} from './helpers'

const { RNNoke } = NativeModules

export default {
  initiateNokeService: RNNoke.initiateNokeService,
  on: onEvent,
  offlineUnlock: RNNoke.offlineUnlock,
  sendCommands: RNNoke.sendCommands,
  addNokeDevice(data) {
    return RNNoke.addNokeDevice(data)
  },
  removeAllNokes: RNNoke.removeAllNokes,
  removeNokeDevice: RNNoke.removeNokeDevice,
  startScan: RNNoke.startScan,
  stopScan: RNNoke.stopScan,
  disconnect: RNNoke.disconnect,
  disconnectAll: RNNoke.disconnectAll,
  getDeviceInfo: RNNoke.getDeviceInfo,
  setOfflineData: RNNoke.setOfflineData,
  addNokeDeviceOnce: RNNoke.addNokeDeviceOnce,
  setAPIKey: RNNoke.setAPIKey,
  fromNokeEvents,
  addNokeDeviceOnce$,
  createNokeOptions,

  AUTHOR: RNNoke.AUTHOR
}