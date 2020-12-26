class Group {
  constructor(api, username, group) {
    /** @type {import('~/plugins/sdk/api').default} */
    this.api = api
    /**
     * @type {{
     *  name: string,
     *  id: string,
     *  admin: string,
     * }}
     */
    this.info = { id: group.id, name: group.name }
    this.members = []
    this.username = username
    this._channels = {}
  }

  /**
   * @param {object} payload
   * @param {string} payload.timestamp
   * @param {string} payload.sender
   * @param {string} payload.message
   */
  addMessage(payload, isActive, channel = this.channel) {
    const time = new Date(payload.timestamp)

    let mins = time.getMinutes().toString()
    mins = mins.length === 1 ? '0' + mins : mins
    let hrs = time.getHours()
    const suffix = hrs >= 12 ? 'pm' : 'am'
    hrs = hrs % 12
    hrs = hrs.toString().length > 1 ? hrs : `0${hrs}`

    const message = {
      title: `${payload.name} at ${hrs}:${mins} ${suffix}`,
      subtitle: payload.message,
      self: payload.sender === this.username,
      sender: payload.sender,
    }

    this._channels[channel].messages.push(message)

    if (!isActive) {
      this._channels[channel].unread++
    }

    return message
  }

  async load() {
    this._channels[this.info.name] = {
      messages: [],
      unread: 0,
    }

    const params = { group: this.info.id, username: this.username }
    const response = await this.api.post('/groups/members', params)

    if (response.status >= 400) {
      return response.statusText
    }

    this.members = response.data.members
    this.info.admin = response.data.group.admin_id
  }

  get messages() {
    return this._channels[this.channel].messages
  }

  get channel() {
    return this.info.name
  }

  markAsRead() {
    this._channels[this.channel].unread = 0
  }

  // noop
  set channel(chan) {}

  listChannels() {
    const channels = []
    for (const [title, { unread }] of Object.entries(this._channels)) {
      channels.push({ title, unread })
    }

    return channels
  }

  async delete() {
    const response = await this.api.post('/groups/remove', {
      group: this.info.id,
      username: this.info.admin,
    })

    if (response.status >= 400) {
      return { error: response.statusText }
    }

    return { status: 200 }
  }

  async kick(username) {
    const payload =
      typeof username === 'string'
        ? { group: this.info.id, username }
        : {
            payload: username.map((n) => ({
              group: this.info.id,
              username: n,
            })),
          }

    const response = await this.api.post('/groups/leave', payload)

    if (response.status >= 400) {
      return { error: response.statusText }
    }

    return response.data
  }

  async invite(username) {
    const payload =
      typeof username === 'string'
        ? { group: this.info.id, username }
        : {
            payload: username.map((n) => ({
              group: this.info.id,
              username: n,
            })),
          }

    const response = await this.api.post('/groups/join', payload)

    if (response.status >= 400) {
      return { error: response.statusText }
    }

    return response.data
  }
}

export class Groups {
  constructor(api, connection) {
    this.username = null
    /** @type {Group[]} */
    this.groups = []

    /** @type {import('~/plugins/sdk/api').default} */
    this.api = api
    /** @type {Group} */
    this._activeGroup = null

    this.modelUpdateFn = null

    /** @type {import('~/plugins/sdk/connection').default} */
    this.connection = connection
    this.connection.addListener('connect', () => {
      this.username = this.connection.username
    })

    this.connection.addListener('group:member_join', (payload) => {
      const group = this.getGroupById(payload.group_id)
      group.members.push(payload)

      if (this.active?.info.id === group.info.id) {
        this.connection.emit('viewUpdate', {
          group: payload.group_id,
        })
      }
    })

    this.connection.addListener('group:member_leave', async (payload) => {
      if (payload.user_id === this.username) {
        await this.exit(payload.group_id, payload.user_id, true)
        return
      }

      const group = this.getGroupById(payload.group_id)
      const idx = group.members.findIndex(
        ({ user_id: username }) => payload.user_id === username
      )

      if (idx >= 0) {
        group.members.splice(idx, 1)
      }

      this.modelUpdateFn?.()
    })
  }

  onNewGroupHandler(fn) {
    this.connection.addListener('group:join', fn)
  }

  onModelUpdate(fn) {
    this.modelUpdateFn = fn
  }

  async load() {
    const params = { username: this.username }
    const response = await this.api.post('/user/memberships', params)

    if (response.status >= 400) {
      return response.statusText
    }

    const memberships = response.data.memberships
    this.groups = []
    for (const { group } of memberships) {
      const g = new Group(this.api, this.username, group)
      await g.load()
      this.groups.push(g)
    }
  }

  async exit(groupId, username, removed = false) {
    const group = this.getGroupById(groupId)
    // group is already deleted
    if (!group) {
      return
    }

    if (!removed) {
      if (group.info.admin === username) {
        await group.delete()
      } else {
        await group.kick(username)
      }
    }

    if (group.info.id === this.active?.info.id) {
      this._activeGroup = null
    }

    const groupIdx = this.groups.findIndex(({ info: { id } }) => id === groupId)
    this.groups.splice(groupIdx, 1)
    this.modelUpdateFn?.()
  }

  async add(group) {
    // Probably this group was created by the same user
    if (this.getGroupById(group.id)) {
      return
    }

    const g = new Group(this.api, this.username, group)
    this.groups.push(g)
    await g.load()
  }

  async create(name, members = []) {
    const params = { group: name, username: this.username, members }
    const response = await this.api.post('/groups/create', params)

    if (response.status >= 400) {
      return response.statusText
    }
  }

  listGroups() {
    return this.groups.map(({ info }) => info)
  }

  /**
   * @param {object} payload
   * @param {string} payload.timestamp
   * @param {string} payload.sender
   * @param {string} payload.message
   * @param {string} groupId
   * @param {string=} channel
   */
  addMessage(payload, groupId = this.active?.info.id, channel) {
    const group = this.getGroupById(groupId)
    return group.addMessage(payload, this.active === group, channel)
  }

  /**
   * @param {string} groupId
   * @returns {Group}
   */
  getGroupById(groupId) {
    return this.groups.find(({ info: { id } }) => groupId === id)
  }

  get active() {
    return this._activeGroup
  }

  set active(groupId) {
    this._activeGroup = this.getGroupById(groupId)
    this._activeGroup.markAsRead()
  }
}
