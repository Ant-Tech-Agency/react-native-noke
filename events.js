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

export const debounceObserver = (observer) => {
  let lastTime = Date.now()

  return (eventName, data) => {
    const newTime = Date.now()
    const timpstamp = (newTime - lastTime)
    console.log('%c timpstamp', 'background: red; color: white', timpstamp)
    if(timpstamp > 1000) {
      observer.next({
        name: eventName,
        data
      })
      lastTime = Date.now()
    }
  }
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

  let timer = null
  let _debounce = null

  return Observable.create(observer => {
    _debounce = debounceObserver(observer)

    events.map(eventName => {
      //if(eventName === 'onNokeConnected') {
      //  onEvent(eventName, (data = {}) => {
      //    _debounce(eventName, data)
      //  })
      //  return
      //}

      if (eventName === 'onNokeSyncing') {
        onEvent(eventName, (data = {}) => {
          timer = setTimeout(() => {
            observer.next({
              name: 'onNokeDisconnected',
              data
            })
          }, 1500)
        })
        return
      }

      if (eventName === 'onNokeConnecting') {
        onEvent(eventName, (data = {}) => {
          timer = setTimeout(() => {
            observer.next({
              name: 'onNokeDisconnected',
              data
            })
          }, 3500)
        })
        return
      }

      if (eventName === 'onNokeUnlocked') {
        onEvent(eventName, (data = {}) => {
          clearTimeout(timer)
          observer.next({
            name: eventName,
            data
          })
        })
        return
      }

      onEvent(eventName, (data = {}) => {
        observer.next({
          name: eventName,
          data
        })
      })
    })
  })
}