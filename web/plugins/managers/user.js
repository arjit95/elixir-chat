export class User {
  constructor(api, connection) {
    /** @type {import('../sdk/api').default} */
    this.api = api
    /** @type {string} */
    this.username = null
    this._channels = {}
    this._channel = null

    // list of people who have sent this user a message.
    // This means that both the parties have agreed that they know each other
    // Now this user can add them to groups etc.
    // username => name
    this.contacts = {}

    connection.addListener('connect', (payload) => {
      this.username = payload.username
    })
  }

  async load(offset = 0, limit = 10) {
    const params = { offset, limit, username: this.username }
    let response = await this.api.post('/user/contacts/available', params)

    if (response.status >= 400) {
      throw new Error(response.statusText)
    }

    response.data.contacts.forEach(({ name, username }) =>
      this.addChannel(username, name)
    )

    // Contacts which have communicated with this user
    response = await this.api.post('/user/contacts/mutual', params)
    if (response.status >= 400) {
      throw new Error(response.statusText)
    }

    this.contacts = response.data.contacts.reduce((acc, { name, username }) => {
      acc[username] = name
      return acc
    }, {})
  }

  addChannel(username, name) {
    if (!this.hasChannel(username)) {
      this._channels[username] = { messages: [], unread: 0, name }
    }
  }

  hasChannel(name) {
    return name in this._channels
  }

  /**
   * @param {object} payload
   * @param {string} payload.timestamp
   * @param {string} payload.message
   * @param {string} payload.name
   * @param {string} payload.sender
   * @param {boolean} payload.blocked
   */
  addMessage(payload) {
    const time = new Date(payload.timestamp)

    let mins = time.getMinutes().toString()
    mins = mins.length === 1 ? '0' + mins : mins
    let hrs = time.getHours()
    const suffix = hrs >= 12 ? 'pm' : 'am'
    hrs = hrs % 12
    hrs = hrs.toString().length > 1 ? hrs : `0${hrs}`

    this.addChannel(payload.channel, payload.name)
    const self = payload.sender === this.username
    const type = payload.type || 'text'
    const message = {
      title: `${hrs}:${mins} ${suffix}`,
      subtitle:
        payload.type === 'image'
          ? URL.createObjectURL(payload.message)
          : payload.message,
      self,
      name: payload.name || this._channels[payload.channel].name,
      type,
    }

    this._channels[payload.channel].messages.push(message)

    if (this.channel !== payload.channel) {
      this._channels[payload.channel].unread++
    }

    if (!self && !payload.blocked) {
      this.contacts[payload.channel] = payload.name
    }

    return message
  }

  listChannels() {
    const channels = []
    for (const [username, { unread, name }] of Object.entries(this._channels)) {
      channels.push({ subtitle: username, unread, title: name, id: username })
    }

    return channels
  }

  listContacts() {
    return Object.entries(this.contacts)
  }

  get messages() {
    return this._channels[this.channel]?.messages || []
  }

  get channel() {
    return this._channel
  }

  set channel(channel) {
    if (this._channels[channel]) {
      this._channels[channel].unread = 0
    }

    this._channel = channel
  }
}
