import {
  NativeEventEmitter,
  NativeModules
} from 'react-native'
import { Observable } from 'rxjs/Observable'

const { RNNoke } = NativeModules
const NokeEmitter = new NativeEventEmitter(RNNoke)

export const onEvent = function (eventName, callback) {
  NokeEmitter.addListener(eventName, callback)
  return this
}

export const addNokeDeviceIfNeeded = (data) => {
  if (Observable) {
    return Observable.create(observer => {
      RNNoke.removeNokeDevice(data.macAddress)
      .then(() => {
        return RNNoke.addNokeDevice({
          name: data.name,
          mac: data.macAddress,
          key: data.key,
          cmd: data.command
        })
      })
      .then(() => {
        return RNNoke.stopScan()
      })
      .then(() => {
        observer.next()
      })
      .catch(() => {
        observer.error(`Can't set data to noke device. Please close your app and open again.`)
      })
    })
  }

  return RNNoke.addNokeDevice(data)
}

export const fromNokeEvents = () => {
  if (!Observable) return {
    message: 'Missing rxjs'
  }

  const events = [
    'onServiceConnected',
    'onNokeDiscovered',
    'onNokeConnecting',
    'onNokeConnected',
    'onNokeSyncing',
    'onNokeUnlocked',
    'onNokeDisconnected',
    'onBluetoothStatusChanged',
    'onError'
  ]

  return Observable.create(observer => {
    events.map(eventName => {
      onEvent(eventName, (data = {}) => {
        observer.next({
          name: eventName,
          data
        })
      })
    })
  })
}