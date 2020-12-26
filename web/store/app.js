const defaultUserInfo = {
  name: null,
  username: null,
  isLoggedIn: false,
}

export const state = () => ({
  darkMode: true,
  userInfo: { ...defaultUserInfo },
})

export const mutations = {
  toggleDarkMode(state, mode) {
    state.darkMode = mode
  },

  setUserInfo(state, info) {
    Object.assign(state.userInfo, info)
  },

  removeUserInfo(state) {
    state.userInfo = { ...defaultUserInfo }
    localStorage.setItem('logout', Date.now())
  },
}
