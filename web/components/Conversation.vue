<template>
  <!--- Header -->
  <v-container fluid>
    <empty-conversation v-if="!title" />
    <div v-else>
      <chat-toolbar
        :title="title"
        :subtitle="subtitle"
        :view="members.length ? 'group' : 'user'"
        @invite="onInvite"
        @kick="onKick"
        @delete="onDelete"
        @block="onBlock"
        @exit="onExit"
      ></chat-toolbar>
      <v-divider></v-divider>

      <v-list ref="messages" class="messages">
        <message
          v-for="message in messages"
          :key="message.title"
          :title="message.title"
          :subtitle="message.subtitle"
          :right="message.self"
          :sender="message.sender"
          :type="message.type"
        />
      </v-list>
    </div>
  </v-container>
</template>

<style lang="scss" scoped>
.messages {
  background-color: transparent;
  overflow-y: auto;
  max-height: 76vh;
  display: flex;
  flex-direction: column;
}
</style>
<script>
import Message from '~/components/Message'
import EmptyConversation from '~/components/EmptyConversation'
import ChatToolbar from '~/components/ChatToolbar'

export default {
  name: 'Conversation',
  components: {
    Message,
    ChatToolbar,
    EmptyConversation,
  },
  props: {
    title: {
      type: String,
      default: null,
    },
    subtitle: {
      type: String,
      default: '',
    },
    members: {
      type: Array,
      default: () => [],
    },
    messages: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      height: 0,
    }
  },
  watch: {
    messages(_val) {
      const ref = this.$refs.messages
      const children = ref?.$children

      if (!children?.length) {
        return
      }

      /**
       * Bring new element into view if the user was already at the previous
       * last message
       */
      if (ref.$el.clientHeight + ref.$el.scrollTop === ref.$el.scrollHeight) {
        // wait for view update
        this.$nextTick(() => {
          const last = children[children.length - 1]
          last?.$el.scrollIntoView()
        })
      }
    },
  },
  methods: {
    onInvite() {
      this.$emit('invite')
    },
    onDelete() {
      this.$emit('delete')
    },
    onBlock() {
      this.$emit('block')
    },
    onKick() {
      this.$emit('kick')
    },
    onExit() {
      this.$emit('exit')
    },
  },
}
</script>
