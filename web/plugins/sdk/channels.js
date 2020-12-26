import { EventEmitter } from 'events'
import { Transport } from '~/plugins/sdk/rtc'

class BaseChannel extends EventEmitter {
  constructor(connection, config) {
    super()
    this.connection = connection
    this.transport = new Transport(connection, config)
    this.onConnectEvent = 'onConnect'
    this.onRequestEvent = 'onRequest'
    this.transport.on('onConnect', this.onConnect.bind(this))
    this.transport.on('onRequest', this.onRequest.bind(this))
  }

  /**
   * Triggered when the connection is established for the
   * receipient
   * @param {object} data
   * @param {Transport} data.instance
   * @param {string} data.receipient
   * @param {Error=} data.error
   */
  onConnect(data) {
    this.emit(this.onConnectEvent, data)
  }

  /**
   * Triggered when a remote user establishes a connection
   * with the current user
   * @param {object} data
   * @param {Transport} data.instance
   * @param {string} data.receipient
   * @param {Error=} data.error
   */
  onRequest(data) {
    this.emit(this.onRequestEvent, data)
  }
}

export class File extends BaseChannel {
  constructor(connection) {
    super(connection)
    this.onConnectEvent = 'onFileSend'
    this.onRequestEvent = 'onFileReceive'
  }

  init(receipient) {
    this.transport.initConnection(receipient)
  }

  /**
   *  @param {Blob} file
   *  @param {Peer} instance
   */
  send(file, { connection }, receipient, chunkSize = 16384) {
    let offset = 0
    const fileReader = new FileReader()

    connection.on('error', (e) => {
      this.emit(this.onConnectEvent, {
        error: e,
        receipient,
      })
    })

    return new Promise((resolve) => {
      const buffer = []
      fileReader.addEventListener('load', (e) => {
        connection.send(e.target.result)
        offset += e.target.result.byteLength
        buffer.push(e.target.result)

        if (offset < file.size) {
          readSlice(offset)
        } else {
          connection.destroy()
          resolve(buffer)
        }
      })

      const readSlice = (o) => {
        const slice = file.slice(offset, o + chunkSize)
        fileReader.readAsArrayBuffer(slice)
      }

      readSlice(0)
    })
  }
}
