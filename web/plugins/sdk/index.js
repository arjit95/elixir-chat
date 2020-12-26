import { Groups, User as Users } from '../managers'
import Connection from './connection'
import Message from './message'
import User from './user'
import { File } from './channels'

import API from './api'

/**
 * @typedef {object} SDK
 * @property {Connection} Connection
 * @property {Message} Message
 * @property {User} User
 * @property {File} File
 * @property {object} Managers
 * @property {Users} Managers.Users
 * @property {Groups} Managers.Groups
 */

export default (context, inject) => {
  const connection = new Connection()
  const message = new Message(connection)

  const api = new API(context)
  const sdk = {
    Connection: connection,
    Message: message,
    User: new User(context, api, connection),
    File: new File(connection),
    Managers: {
      Users: new Users(api, connection),
      Groups: new Groups(api, connection),
    },
  }

  inject('sdk', sdk)
}
