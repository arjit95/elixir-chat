<template>
  <v-row class="input-row">
    <VEmojiPicker
      v-show="isEmojiVisible"
      class="emoji-selector"
      @select="selectEmoji"
    />
    <v-textarea
      v-model="message"
      class="message-input"
      label="Enter your message..."
      outlined
      filled
      dense
      append-outer-icon="mdi-send"
      shaped
      prepend-icon="mdi-emoticon"
      prepend-inner-icon="mdi-paperclip"
      clearable
      single-line
      rows="1"
      @click:prepend="toggleEmoji"
      @click:append-outer="sendMessage"
      @click:prepend-inner="$refs.image.click()"
      @keyup.enter="sendMessage($event)"
    ></v-textarea>
    <input
      ref="image"
      type="file"
      style="display: none"
      accept="image/*"
      @change="onFilePicked"
    />
  </v-row>
</template>

<style lang="scss" scoped>
.message-input {
  max-height: 60vh;
  overflow-y: auto;
  overflow-x: hidden;
}

.emoji-selector {
  position: absolute;
  margin-top: -32%;
  z-index: 99999;
}
</style>
<script>
import { VEmojiPicker } from 'v-emoji-picker'

export default {
  name: 'MessageInput',
  components: {
    VEmojiPicker,
  },

  data() {
    return {
      message: '',
      isEmojiVisible: false,
    }
  },
  methods: {
    closeConditional() {
      return !this.isEmojiVisible
    },

    toggleEmoji() {
      this.isEmojiVisible = !this.isEmojiVisible
    },

    selectEmoji(emoji) {
      this.message += emoji.data
    },
    /**
     * @param {KeyboardEvent} event
     */
    sendMessage(event) {
      if (event.shiftKey) {
        return
      }

      event.preventDefault()

      let message = this.message
      message = message.split('\n')
      if (message[message.length - 1].trim() === '') {
        message.splice(message.length - 1, 1)
      }

      message = message.join('\n')
      if (message.length) {
        this.$emit('send', message)
        this.message = ''
      }
    },

    onFilePicked(event) {
      const [file] = event.target.files
      if (!file) {
        return
      }

      this.$emit('attachment', file)
    },
  },
}
</script>
