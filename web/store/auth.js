export const state = () => {
  return {
    token: null,
    expiry: null,
  }
}
export const mutations = {
  setAuth(state, { token, expiry }) {
    state.token = token
    state.expiry = expiry
  },
}
