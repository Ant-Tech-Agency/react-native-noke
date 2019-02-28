import { NativeModules } from 'react-native'
import { changeLock$, createOptions, fetchNokeData } from './helpers'
import { fromNokeEvents, addListener } from './events'
import { constants } from './constants'

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
  createOptions,
  fetchNokeData,

  fromNokeEvents,
  addListener,

  CONSTANTS: constants
}