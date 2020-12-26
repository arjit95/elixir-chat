<template>
  <v-row class="fill-height" no-gutters>
    <v-navigation-drawer v-model="drawer" width="286" permanent>
      <v-row class="fill-height nav-container" no-gutters>
        <v-navigation-drawer mini-variant permanent mini-variant-width="66">
          <v-list nav dense class="icon-row">
            <v-list-item :ripple="false" dense @click="setUserView()">
              <v-list-item-avatar :title="username" style="overflow: visible">
                <v-badge color="primary" :value="getUnread()" overlap dot>
                  <text-avatar :name="username" :size="36" />
                </v-badge>
              </v-list-item-avatar>
            </v-list-item>
            <v-divider></v-divider>
            <create-group
              :group="groupManagementPopup.group"
              :opened="groupManagementPopup.opened"
              :operation="groupManagementPopup.operation"
              :contacts="groupManagementPopup.contacts"
              @close="onGroupManagementPopupClose"
              @create="groupManagementPopup.onCreate"
              @open="groupManagementPopup.onOpen"
              @kick="groupManagementPopup.onKick"
              @invite="groupManagementPopup.onInvite"
            >
              <template #icon>
                <v-avatar icon>
                  <v-icon color="primary">mdi-plus</v-icon>
                </v-avatar>
              </template>
            </create-group>

            <v-list-item @click="logout()">
              <v-list-item-avatar style="overflow: visible">
                <v-icon>mdi-logout</v-icon>
              </v-list-item-avatar>
            </v-list-item>

            <!-- Group list !-->
            <v-list-item
              v-for="i in groups"
              :key="i.name"
              :ripple="false"
              @click="setGroupView(i)"
            >
              <v-list-item-avatar :title="i.name" style="overflow: visible">
                <v-badge color="primary" :value="getUnread(i.id)" overlap dot>
                  <text-avatar :size="36" :name="i.name" />
                </v-badge>
              </v-list-item-avatar>
            </v-list-item>
          </v-list>
        </v-navigation-drawer>
        <v-list max-width="210" shaped>
          <search-bar @select="onSearchSelect"></search-bar>
          <v-subheader class="text-overline">{{
            activeView === 'user' ? 'Conversations' : 'Channels'
          }}</v-subheader>
          <v-list-item-group color="primary">
            <v-list-item
              v-for="i in channels"
              :key="i.title"
              dense
              two-line
              @click="setActiveChannel(i)"
            >
              <v-list-item-avatar>
                <text-avatar :name="i.title" :size="32" />
              </v-list-item-avatar>
              <v-list-item-content>
                <v-list-item-title :title="i.title">{{
                  i.title
                }}</v-list-item-title>
                <v-list-item-subtitle v-if="i.subtitle">
                  {{ i.subtitle }}</v-list-item-subtitle
                >
              </v-list-item-content>
              <v-list-item-action v-if="i.unread">
                <v-list-item-action-text>
                  {{ i.unread }}
                </v-list-item-action-text>
              </v-list-item-action>
            </v-list-item>
          </v-list-item-group>
        </v-list>
      </v-row>
    </v-navigation-drawer>
    <v-col class="chat column" cols="9">
      <conversation
        class="message-list"
        :title="conversation.title"
        :subtitle="conversation.subtitle"
        :members="conversation.members"
        :messages="conversation.messages"
        @invite="onInvite"
        @delete="onDelete"
        @kick="onKick"
        @block="onBlock"
        @exit="onExit"
      ></conversation>
      <div v-if="conversation.title" class="message-container">
        <message-input
          class="message-input mx-auto"
          @send="sendMessage"
          @attachment="onAttachment"
        />
      </div>
    </v-col>
  </v-row>
</template>

<style lang="scss" scoped>
.unread {
  border-left: 1px solid var(--v-primary-base);
}

.nav-container {
  flex-wrap: nowrap;
}

.autocomplete {
  max-width: 90%;
  margin: 0 auto !important;
}

.icon-row {
  display: flex;
  flex-direction: column;
  padding: 0;

  .v-list-item {
    margin-left: 0;
    margin-right: 0;
    padding-left: 0;
    padding-right: 0;
    flex: 1;

    .v-avatar {
      margin-left: auto;
      margin-right: auto;
      padding: 0;
    }
  }
}

.column {
  padding: 0;
}

.chat {
  background-color: rgb(54, 57, 63);
  flex: 1 1;
  max-width: 100%;
  display: flex;
  flex-direction: column;

  .message-list {
    flex: 1 0;
    padding: 0;
    overflow: hidden;
  }

  .message-input {
    flex: 0 0 90%;
  }

  .message-container {
    min-height: 15%;
    max-height: 60%;
    background: rgba(32, 34, 37, 1);
    display: flex;
    align-items: flex-end;
  }
}
</style>
<script>
import TextAvatar from '~/components/TextAvatar.vue'
import MessageInput from '~/components/MessageInput'
import Conversation from '~/components/Conversation'
import CreateGroup from '~/components/CreateGroup'
import SearchBar from '~/components/SearchBar'

/**
 * @typedef {import('../plugins/sdk/').SDK} SDK
 */

export default {
  components: {
    MessageInput,
    Conversation,
    CreateGroup,
    TextAvatar,
    SearchBar,
  },

  middleware: 'authenticated',

  /**
   * @param {object} context
   * @param {SDK} context.$sdk
   */
  async asyncData({ store, $sdk, redirect }) {
    let username = store.state.app.userInfo.username
    if (!username) {
      // temp hack until login is implemented
      const url = new URL(window.location.href)
      username = url.searchParams.get('user')
    }

    const response = { username }
    if (username) {
      $sdk.Connection.connect(username)
      const { name } = await new Promise((resolve) => {
        $sdk.Connection.addListener('connect', async (payload) => {
          await $sdk.Managers.Users.load()
          await $sdk.Managers.Groups.load()
          resolve(payload)
        })
      })

      response.name = name
    }

    if (!username) {
      await $sdk.User.logout()
      return redirect('/login')
    }

    return response
  },

  data() {
    /** @type {SDK} */
    const sdk = this.$sdk

    return {
      conversation: {
        title: null,
        subtitle: null,
        members: [],
        messages: [],
      },
      activeView: 'user',
      channels: [],
      groups: [],
      fileTransfers: {},
      drawer: false,
      groupManagementPopup: {
        group: null,
        opened: false,
        operation: 0,
        contacts: sdk.Managers.Users.listContacts().map(
          ([username]) => username
        ),
        // On new group create
        onCreate: async ({ name, members }) => {
          await sdk.Managers.Groups.create(name, members)
          this.updateView()
          this.groupManagementPopup.opened = false
        },
        onKick: async ({ members }) => {
          await sdk.Managers.Groups.active.kick(members)
        },
        onInvite: async ({ members }) => {
          await sdk.Managers.Groups.active.invite(members)
        },
        onOpen: (operation) => {
          const members =
            sdk.Managers.Groups.active?.members.map((user) => user.user_id) ||
            []

          const contacts = sdk.Managers.Users.listContacts().map(
            ([username]) => username
          )

          switch (operation) {
            case 0: // create group
              this.groupManagementPopup.contacts = contacts
              break
            case 1: // kick
              this.groupManagementPopup.contacts = members
              break
            case 2: // invite
              this.groupManagementPopup.contacts = contacts.filter(
                (c) => !members.includes(c)
              )
              break
          }
        },
      },
    }
  },

  mounted() {
    if (!this.username) {
      return
    }

    /** @type {SDK} */
    const sdk = this.$sdk
    sdk.Message.onNewMessageHandler(this.onNewMessage.bind(this))
    sdk.Managers.Groups.onNewGroupHandler(this.onNewGroup.bind(this))
    sdk.Managers.Groups.onModelUpdate(() => {
      if (this.activeView === 'group' && !sdk.Managers.Groups.active) {
        this.activeView = 'user'
        this.conversation.title = null
        this.updateView()
      } else {
        this.updateView({ message: false })
      }
    })

    // We are ready to send the file
    sdk.File.addListener('onFileSend', this.onFileSend.bind(this))
    // We are going to receive a file
    sdk.File.addListener('onFileReceive', this.onFileReceive.bind(this))

    this.updateView()
  },

  methods: {
    // Open popup and show upload
    async onFileSend(payload) {
      const file = this.fileTransfers[payload.receipient]
      delete this.fileTransfers[payload.receipient]
      if (payload.error) {
        this.$dialog.notify.warning(
          `P2P: Error while sending file to ${payload.receipient}: ${payload.error.message}
           
           To save server resources we perform on-demand connection. Try sending a message to
           initiate a connection which will connect the user if he is online
          `,
          {
            position: 'top-right',
            timeout: 5000,
          }
        )

        return
      }

      const buffered = await this.$sdk.File.send(
        file,
        payload.instance,
        payload.receipient
      )
      /** @type {SDK} */
      const sdk = this.$sdk
      sdk.Managers.Users.addMessage({
        timestamp: Date.now(),
        message: new Blob(buffered),
        sender: this.username,
        channel: payload.receipient,
        name: this.name,
        type: 'image',
      })
    },

    onFileReceive(payload) {
      if (payload.error instanceof window.RTCErrorEvent) {
        if (payload.error.error.code === 0) {
          return
        }

        payload.error = payload.error.error
      }

      if (payload.error) {
        this.$dialog.notify.warning(
          `P2P: Error while receiving file from ${payload.sender}: ${payload.error.message}`,
          {
            position: 'top-right',
            timeout: 5000,
          }
        )

        return
      }

      const buffered = []
      payload.instance.connection.on('close', () => {
        this.$sdk.Managers.Users.addMessage({
          timestamp: Date.now(),
          message: new Blob(buffered),
          sender: payload.sender,
          channel: payload.sender,
          type: 'image',
        })
      })

      payload.instance.connection.on('data', (data) => {
        buffered.push(data)
      })
    },

    getUnread(groupId) {
      /** @type {SDK} */
      const sdk = this.$sdk
      let unreads = 0
      if (!groupId) {
        unreads = sdk.Managers.Users.listChannels().reduce(
          (acc, { unread }) => acc + unread,
          unreads
        )
      } else {
        const group = sdk.Managers.Groups.getGroupById(groupId)
        unreads =
          group
            ?.listChannels()
            .reduce((acc, { unread }) => acc + unread, unreads) || 0
      }

      return unreads > 10 ? '10+' : unreads
    },

    updateView(updateInfo = { messages: true, channels: true, groups: true }) {
      if (updateInfo.groups !== false) {
        this.updateGroups()
      }

      if (updateInfo.channels !== false) {
        this.updateChannels()
      }

      if (updateInfo.messages !== false) {
        this.updateMessages()
      }
    },

    updateGroups() {
      /** @type {SDK} */
      const sdk = this.$sdk
      this.groups = sdk.Managers.Groups.listGroups()
    },

    updateChannels() {
      /** @type {SDK} */
      const sdk = this.$sdk
      this.channels =
        (this.activeView === 'user'
          ? sdk.Managers.Users.listChannels()
          : sdk.Managers.Groups.active?.listChannels()) || []
    },

    updateMessages() {
      /** @type {SDK} */
      const sdk = this.$sdk
      this.conversation.messages =
        (this.activeView === 'user'
          ? sdk.Managers.Users.messages
          : sdk.Managers.Groups.active?.messages) || []
    },

    setGroupView(group) {
      /** @type {SDK} */
      const sdk = this.$sdk
      sdk.Managers.Groups.active = group.id
      this.activeView = 'group'
      // TODO: Remove once we have support for channels
      this.setActiveChannel({ title: group.name, id: group.id })
      this.updateView()
    },

    setUserView() {
      this.activeView = 'user'

      /** @type {SDK} */
      const sdk = this.$sdk
      let currentChannel = sdk.Managers.Users.channel
      if (currentChannel) {
        currentChannel = sdk.Managers.Users.listChannels().find(
          ({ id }) => id === currentChannel
        )
      }

      if (currentChannel) {
        this.setActiveChannel(currentChannel)
      }

      this.updateView()
    },

    setActiveChannel(channel) {
      /** @type {SDK} */
      const sdk = this.$sdk
      if (this.activeView === 'user') {
        sdk.Managers.Users.addChannel(channel.id, channel.title)
        sdk.Managers.Users.channel = channel.id
        this.conversation.title = channel.title // name
        this.conversation.subtitle = `@${channel.subtitle}` // username
        this.conversation.members = []
      } else {
        sdk.Managers.Groups.active.channel = channel.id
        this.conversation.title = channel.title

        const members = sdk.Managers.Groups.active.members
        this.conversation.subtitle = `${members.length} members`
        this.conversation.members = members
      }

      this.updateView()
    },

    async onNewGroup({ group }) {
      /** @type {SDK} */
      const sdk = this.$sdk
      await sdk.Managers.Groups.add(group)
      this.updateView()
    },

    onNewMessage(body) {
      /** @type {SDK} */
      const sdk = this.$sdk
      const channel = body.group ? body.group : body.sender

      if (!body.group) {
        body = { ...body, channel }
        sdk.Managers.Users.addMessage(body)
      } else {
        sdk.Managers.Groups.addMessage(body, body.group)
      }

      let canUpdateMessage = false
      if (this.activeView === 'user') {
        canUpdateMessage = sdk.Managers.Users.channel === body.channel
      } else {
        canUpdateMessage = sdk.Managers.Groups.active.info.id === body.group
      }

      // messages should update by reference
      this.updateView({ messages: !canUpdateMessage })
    },

    sendMessage(message) {
      /** @type {SDK} */
      const sdk = this.$sdk
      if (this.activeView === 'user') {
        const receipient = sdk.Managers.Users.channel
        // Add message to view
        sdk.Managers.Users.addMessage({
          timestamp: Date.now(),
          message,
          sender: this.username,
          channel: receipient,
          name: this.name,
        })

        // Send message to user
        sdk.Message.user(sdk.Managers.Users.channel, message)
      } else {
        sdk.Message.group(sdk.Managers.Groups.active.info.id, message)
      }

      this.updateView({ messages: false })
    },

    openGroup() {
      this.groupManagementPopup.opened = true
      this.groupManagementPopup.onOpen(this.groupManagementPopup.operation)
    },

    // Invite new member to group
    onInvite() {
      /** @type {SDK} */
      const sdk = this.$sdk
      this.groupManagementPopup.group = sdk.Managers.Groups.active
      this.groupManagementPopup.operation = 2

      this.openGroup()
    },

    // Delete group
    onDelete() {},

    // Block member from current conversation
    onBlock() {
      /** @type {SDK} */
      const sdk = this.$sdk
      sdk.User.block(sdk.Managers.Users.channel)
    },

    onKick() {
      /** @type {SDK} */
      const sdk = this.$sdk
      this.groupManagementPopup.group = sdk.Managers.Groups.active
      this.groupManagementPopup.operation = 1
      this.openGroup()
    },

    async onExit() {
      /** @type {SDK} */
      const sdk = this.$sdk
      const activeGroup = sdk.Managers.Groups.active
      if (this.username === activeGroup.info.admin) {
        const response = await this.$dialog.confirm({
          text:
            'Since you are an admin, the group will also be deleted. Do you want to proceed?',
          title: 'Warning',
        })

        if (!response) return
      } else {
        const response = await this.$dialog.confirm({
          text: 'Are you sure you want to exit this group',
          title: 'Warning',
        })

        if (!response) return
      }

      await sdk.Managers.Groups.exit(this.username, activeGroup.info.id)
    },

    onGroupManagementPopupClose() {
      this.groupManagementPopup.opened = false
      this.groupManagementPopup.group = null
      this.groupManagementPopup.operation = 0
    },

    onSearchSelect(val) {
      this.activeView = 'user'
      this.setActiveChannel(val)
      this.updateView()
    },

    onAttachment(file) {
      /** @type {SDK} */
      const sdk = this.$sdk
      if (this.activeView === 'user') {
        sdk.File.init(sdk.Managers.Users.channel)
        this.fileTransfers[sdk.Managers.Users.channel] = file
      }
    },

    async logout() {
      await this.$sdk.User.logout()
      this.$router.push('/login')
    },
  },
}
</script>
