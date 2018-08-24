import { debounce } from 'lodash'
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
  let lastEvent = ''

  return Observable.create(observer => {
    onEvent('onNokeDiscovered', data => {
      observer.next({
        name: 'onNokeDiscovered',
        data
      })
      lastEvent = 'onNokeDiscovered'
    })

    onEvent('onNokeConnecting', data => {
      observer.next({
        name: 'onNokeConnecting',
        data
      })
      lastEvent = 'onNokeConnecting'

      //timer = setTimeout(() => {
      //  observer.next({
      //    name: 'onNokeDisconnected',
      //    data
      //  })
      //  lastEvent = 'onNokeDisconnected'
      //}, 5000)
    })

    onEvent('onNokeConnected', data => {
      //clearTimeout(timer)
      if(lastEvent !== 'onNokeUnlocked') {
        observer.next({
          name: 'onNokeConnected',
          data
        })
        lastEvent = 'onNokeConnected'
      }
    })

    onEvent('onNokeSyncing', data => {
      observer.next({
        name: 'onNokeSyncing',
        data
      })
      lastEvent = 'onNokeSyncing'

      //timer = setTimeout(() => {
      //  observer.next({
      //    name: 'onNokeDisconnected',
      //    data
      //  })
      //  lastEvent = 'onNokeDisconnected'
      //}, 1500)
    })

    onEvent('onNokeUnlocked', data => {
      //clearTimeout(timer)
      observer.next({
        name: 'onNokeUnlocked',
        data
      })
      lastEvent = 'onNokeUnlocked'
    })

    onEvent('onNokeDisconnected', data => {
      observer.next({
        name: 'onNokeDisconnected',
        data
      })
      lastEvent = 'onNokeDisconnected'
    })

    onEvent('onError', data => {
      observer.next({
        name: 'onError',
        data
      })
      lastEvent = 'onError'
    })

  })
}