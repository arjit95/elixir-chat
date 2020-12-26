import axios from 'axios'

export default class {
  constructor({ store, $config }) {
    this.api = axios.create({
      baseURL: $config.apiURL,
      withCredentials: true,
    })

    this.store = store
  }

  post(
    url,
    data,
    params = { headers: { 'Content-Type': 'application/json' } }
  ) {
    data.token = this.store.state.auth.token
    return this.api.post(url, JSON.stringify(data), params)
  }

  get(url) {
    return this.api.get(url)
  }
}
