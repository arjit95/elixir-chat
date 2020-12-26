export default class {
  constructor({ store }, api, connection) {
    /** @type {import('~/plugins/sdk/api').default} */
    this.api = api

    this.store = store

    this.connection = connection
  }

  /**
   * Persist user info in vuex state
   * @param {object} data
   * @property {string} data.token
   * @property {string} data.name
   * @property {string} data.username
   */
  setUserInfo(data) {
    const { token, expiry, username, name } = data
    this.store.commit('auth/setAuth', { token, expiry })

    // Do not store empty metadata
    if (username && name) {
      this.store.commit('app/setUserInfo', { username, name, isLoggedIn: true })
    }
  }

  /**
   * @param {Object} params
   * @param {string} params.from
   * @param {string} params.to
   */
  async block(params) {
    const response = await this.api.post('/user/block', params)
    if (response.status >= 400) {
      return false
    }

    return true
  }

  async search(query) {
    const username = this.connection.username
    const response = await this.api.post('/user/search', { query, username })
    if (response.status >= 400) {
      return { error: response.statusText }
    }

    return { results: response.data.results }
  }

  /**
   * @param {Object} params
   * @param {string} params.username
   * @param {string} params.password
   */
  async login(params) {
    const response = await this.api.post('/auth/login', params)

    if (response.status !== 200) {
      return { error: response.statusText }
    }

    this.setUserInfo(response.data)
    return {}
  }

  async logout() {
    await this.api.get('/auth/logout')
    this.store.commit('auth/setAuth', {
      token: null,
      expiry: null,
    })

    this.store.commit('app/removeUserInfo')
  }

  async refresh() {
    try {
      const oldToken = this.store.state.auth.token || 'invalidToken'
      const response = await this.api.post('/refresh_token', {
        token: oldToken,
      })

      if (response.status >= 400) {
        throw response.statusText
      }

      this.setUserInfo(response.data)
      return response.data
    } catch (error) {
      return { error }
    }
  }

  /**
   * @param {Object} params
   * @param {string} params.username
   * @param {string} params.name
   * @param {string} params.password
   * @param {string} params.email
   */
  async register(params) {
    const response = await this.api.post('/auth/create', params)
    if (response.status >= 400) {
      return response.statusText
    }

    return this.login({
      username: params.username,
      password: params.password,
    })
  }
}
