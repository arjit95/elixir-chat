import Token from '~/plugins/Token'

export default async function ({ $sdk, store, error }) {
  const token = new Token(store.state.auth.expiry, store)
  token.setRefreshHandler(() => $sdk.User.refresh())
  token.setLogoutHandler(async () => {
    await $sdk.User.logout()
    window.location.href = '/login'
  })

  if (!store.state.app.userInfo.isLoggedIn) {
    return
  }

  const err = await token.init()
  if (err) {
    return error({
      statusCode: 500,
      message: err,
    })
  }
}
