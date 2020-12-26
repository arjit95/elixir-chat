export default class {
  constructor(connection) {
    /** @type {import('~/plugins/sdk/connection').default} */
    this.connection = connection
  }

  onNewMessageHandler(fn) {
    this.connection.addListener('user:message_reply', fn)
    this.connection.addListener('group:message_reply', fn)
  }

  /**
   * @param {string} receipient
   * @param {string} message
   */
  user(receipient, message) {
    const body = {
      event: 'user:message_send',
      receipient,
      message,
    }

    this.connection.sendMessage(body)
  }

  /**
   * @param {string} id
   * @param {string} message
   */
  group(id, message) {
    this.connection.sendMessage({
      event: 'group:message_send',
      group: id,
      message,
    })
  }
}
