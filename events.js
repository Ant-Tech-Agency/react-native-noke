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

export const addNokeAndStopScan = data => {
  return RNNoke.addNokeDevice({
    name: data.name,
    mac: data.macAddress,
    key: data.key,
    cmd: data.command
  })
  .then(() => {
    return RNNoke.stopScan()
  })
}

export const addNokeFactory = removeNokeP => data => {
  if (!Observable) return {
    message: 'Missing rxjs'
  }

  if (Observable) {
    return Observable.create(observer => {
      removeNokeP(data)
      .then(() => {
        return addNokeAndStopScan(data)
      })
      .then(() => {
        observer.next()
      })
      .catch(() => {
        observer.error(`Can't set data to noke device. Please close your app and open again.`)
      })
    })
  }
}

export const addNokeDeviceIfNeeded = (data) => {
  return addNokeFactory(() => RNNoke.removeNokeDevice(data.macAddress))(data)
}

export const addNokeDeviceOnce = (data) => {
  return addNokeFactory(() => RNNoke.removeAllNokes())(data)
}

export const fromNokeEvents = () => {
  if (!Observable) return {
    message: 'Missing rxjs'
  }

  console.log('%c testtt', 'background: red; color: white', )

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