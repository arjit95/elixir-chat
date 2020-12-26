import { EventEmitter } from 'events'

export default class extends EventEmitter {
  constructor() {
    super()

    /** @type {string} */
    this.username = null
    /** @type {WebSocket} */
    this.socket = null
    /** @type {number} */
    this.timer = null
  }

  /**
   * @private
   */
  startHeartbeat() {
    if (this.timer) {
      clearTimeout(this.timer)
    }

    this.timer = setInterval(() => {
      if (
        this.socket.readyState === this.socket.CLOSED ||
        this.socket.readyState === this.socket.CLOSING
      ) {
        clearInterval(this.timer)
        return
      }

      this.sendMessage('PING')
    }, 25 * 1000)
  }

  sendMessage(message) {
    if (typeof message === 'object') {
      message = JSON.stringify(message)
    }

    this.startHeartbeat()
    this.socket.send(message)
  }

  /**
   * @private
   */
  onMessage({ data }) {
    if (!(data === 'ok' || data === 'PING')) {
      try {
        const body = typeof data === 'object' ? data : JSON.parse(data)
        if (this.listenerCount(body.event)) {
          this.emit(body.event, body)
        }
      } catch (err) {
        // eslint-disable-next-line no-console
        console.log(err)
      }
    }

    this.startHeartbeat()
  }

  addUser(receipient) {
    const message = {
      event: 'user:connecting',
      username: receipient,
    }

    this.sendMessage(message)
  }

  connect(username) {
    if (this.socket) {
      return
    }

    this.username = username

    const protocol = window.location.protocol === 'https:' ? 'wss://' : 'ws://'
    const url =
      protocol +
      [window.location.hostname, window.location.port]
        .filter((n) => !!n)
        .join(':') +
      '/ws'
    this.socket = new WebSocket(url)
    this.socket.onopen = () => {
      this.sendMessage({ event: 'authenticate', username: this.username })
    }

    this.socket.onmessage = this.onMessage.bind(this)
    this.socket.onclose = () => {}

    this.removeAllListeners('authenticate')
    this.addListener('authenticate', (payload) => {
      this.startHeartbeat()
      this.emit('connect', payload)
    })
  }
}
