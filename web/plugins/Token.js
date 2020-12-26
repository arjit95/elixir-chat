export default class {
  constructor(expiry, store) {
    this.timer = null
    this.refreshFn = null
    this.logoutFn = null
    this.store = store

    this.expiry = expiry
    window.onstorage = this.monitorStorage.bind(this)
  }

  async monitorStorage(event) {
    if (event.key === 'logout') {
      this.destroy()
      await this.logoutFn()
    }
  }

  setRefreshHandler(handler) {
    this.refreshFn = handler
  }

  setLogoutHandler(handler) {
    this.logoutFn = handler
  }

  async onExpire() {
    const response = await this.refreshFn()
    if (response.error) {
      return response.error
    }

    this.expiry = response.expiry
  }

  async init() {
    // Refresh before 3mins of actual expiration
    let remaining =
      typeof this.expiry === 'number' ? this.expiry - 3 * 60 * 1000 : 0

    if (this.timer) {
      this.destroy()
    }

    if (remaining <= 0) {
      const error = await this.onExpire()
      if (error) {
        return error
      }

      remaining = this.expiry - 3 * 60 * 1000
    }

    this.timer = setTimeout(async () => await this.init(), remaining)
  }

  destroy() {
    clearTimeout(this.timer)
    this.timer = null
  }
}
