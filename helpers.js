import { Observable } from 'rxjs/Observable'
import RNNoke from './index'

export const createNokeOptions = options => ({
  url: `https://v1.api.nokepro.com/lock/${options.url}`,
  method: 'POST',
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
    Authorization: 'Bearer ' + options.token
  },
  body: options.body
})

export const changeLock$ = (mac) => new Observable(observer => {
  RNNoke.changeLock(mac)
  .then(data => {
    observer.next(data)
  })
  .catch(err => {
    observer.error(err)
  })
  .finally(() => {
    observer.complete()
  })
})