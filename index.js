import {
  NativeEventEmitter,
  NativeModules
} from 'react-native'
import { changeLock$, createNokeOptions } from './helpers'
import { fromNokeEvents } from './events'

const { RNNoke } = NativeModules

export default {
  initService: RNNoke.initService,
  changeLock: RNNoke.changeLock,
  deviceInfo: RNNoke.deviceInfo,
  disconnect: RNNoke.disconnect,
  startScan: RNNoke.startScan,
  stopScan: RNNoke.stopScan,
  unlock: RNNoke.unlock,
  unlockOffline: RNNoke.unlockOffline,
  changeLock$,
  createNokeOptions,
  fromNokeEvents
}