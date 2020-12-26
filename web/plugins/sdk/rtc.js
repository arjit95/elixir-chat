import { EventEmitter } from 'events'
import SimplePeer from 'simple-peer'

export class Peer {
  constructor(initiator = false) {
    this.connection = new SimplePeer({
      initiator,
      trickle: false,
    })
  }

  waitForEvent(event = 'signal') {
    return new Promise((resolve) => {
      const onSignal = (data) => {
        this.connection.off(event, onSignal)
        resolve(data)
      }

      this.connection.on(event, onSignal)
    })
  }

  getSignalData() {
    return this.waitForEvent()
  }
}

class TimeoutPromise {
  static getPromise(timeout, promise) {
    let timer
    const timeoutPromise = new Promise((resolve, reject) => {
      timer = setTimeout(
        () => reject(Error('Timeout while wating for promise')),
        timeout
      )
    })

    return Promise.race([promise, timeoutPromise])
      .then((result) => {
        return result
      })
      .finally(() => {
        clearTimeout(timer)
      })
  }
}

export class Transport extends EventEmitter {
  constructor(connection) {
    super()

    /** @type {import('./connection').default} */
    this.connection = connection
    this.connection.addListener('user:rtc_offer', this.onOffer.bind(this))
    this.connection.addListener('user:rtc_answer', this.onAnswer.bind(this))
    this.answerStore = {}
  }

  /**
   * @private
   */
  async onOffer(payload) {
    if (payload.error) {
      if (this.answerStore[payload.sender]) {
        this.answerStore[payload.sender][1](new Error(payload.error))
      } else {
        this.emit('onConnect', {
          error: new Error(payload.error),
          receipient: payload.sender,
        })
      }

      return
    }

    // Someone sent this user an offer he now has to reply with an answer
    const transfer = new Peer(false)
    transfer.connection.signal(payload.offer)
    const answer = await transfer.getSignalData()

    this.connection.sendMessage({
      event: 'user:rtc_answer',
      receipient: payload.sender,
      answer,
    })

    transfer.connection.on('error', (err) => {
      this.emit('onRequest', {
        error: err,
        sender: payload.sender,
      })
    })

    transfer.connection.on('connect', () => {
      this.emit('onRequest', {
        instance: transfer,
        sender: payload.sender,
      })
    })
  }

  /**
   * @private
   **/
  onAnswer(payload) {
    const store = this.answerStore[payload.sender]
    const [resolve, reject] = store
    // Error while delivering answer to user, the user could've went offline when we were
    // trying to deliver the answer
    if (payload.error) {
      return reject(new Error(payload.error))
    }

    resolve(payload)
    delete this.answerStore[payload.sender]
  }

  async initConnection(receipient, timeout = 5000) {
    try {
      const transfer = new Peer(true)

      const offer = await transfer.getSignalData()
      const promise = new Promise((resolve, reject) => {
        this.connection.sendMessage({
          event: 'user:rtc_offer',
          receipient,
          offer,
        })

        this.answerStore[receipient] = [resolve, reject]
      })

      // Response arrived from other side
      const { answer } = await TimeoutPromise.getPromise(timeout, promise)

      transfer.connection.signal(answer)
      await transfer.waitForEvent('connect')
      this.emit('onConnect', {
        instance: transfer,
        receipient,
      })
    } catch (err) {
      this.emit('onConnect', {
        receipient,
        error: err,
      })
    }
  }
}
