<template>
  <v-list-item :class="rtlCSS">
    <v-list-item-avatar v-if="sender" class="user-avatar mb-6">
      <text-avatar :name="sender" :size="32" />
    </v-list-item-avatar>

    <v-list-item-content class="message-content">
      <v-list-item-title v-if="title" class="user-name">{{
        title
      }}</v-list-item-title>
      <div v-if="type === 'text'" class="speech-bubble">
        <v-list-item-subtitle class="user-message">{{
          subtitle
        }}</v-list-item-subtitle>
      </div>
      <v-list-item-subtitle v-else-if="type === 'image'" class="user-image">
        <img :src="subtitle" />
      </v-list-item-subtitle>
    </v-list-item-content>
  </v-list-item>
</template>

<style lang="scss" scoped>
.message-container {
  max-width: 50vw;
  overflow: hidden;
}

.right.message-container {
  align-self: flex-end;
}

.user-image img {
  width: 25vw;
  height: 25vw;
}

.user-name {
  font-size: 14px;
  color: var(--v-primary-lighten1);
  align-self: flex-start;
}

.message-content {
  flex: initial;
  flex-wrap: nowrap;
  flex-direction: column;
  overflow: visible;
  align-items: flex-start;
}

.speech-bubble {
  position: relative;
  border-radius: 0.4em;
}

.user-message {
  background-color: var(--v-primary-base);
  padding-top: 8px;
  padding-bottom: 8px;
  white-space: pre-wrap;
  word-break: break-all;
}

.user-avatar {
  align-self: flex-start;
}

.left {
  .user-message {
    padding-left: 10px;
    padding-right: 18px;
    border-radius: 0 10px 10px 10px;
  }

  .speech-bubble:after {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    width: 0;
    height: 0;
    border: 20px solid transparent;
    border-right-color: var(--v-primary-base);
    border-left: 0;
    border-top: 0;
    margin-left: -12px;
  }
}

.right {
  flex-direction: row-reverse;

  .message-content {
    text-align: right;
    margin-right: 12px;
  }

  .user-name,
  .speech-bubble {
    align-self: flex-end;
  }

  .user-message {
    align-self: flex-end;
    text-align: right;
    padding-left: 18px;
    padding-right: 10px;
    border-radius: 10px 0 10px 10px;
    margin-right: 6px;
  }

  .speech-bubble:after {
    content: '';
    position: absolute;
    right: 0;
    top: 0;
    width: 0;
    height: 0;
    border: 30px solid transparent;
    border-left-color: var(--v-primary-base);
    border-right: 0;
    border-top: 0;
    margin-right: -15px;
  }

  .user-avatar {
    margin-right: 0;
    margin-left: 6px;
  }
}
</style>
<script>
export default {
  name: 'Message',
  props: {
    title: {
      type: String,
      default: '',
    },
    subtitle: {
      type: String,
      default: '',
    },
    sender: {
      type: String,
      default: '',
    },
    right: {
      type: Boolean,
      default: false,
    },
    type: {
      type: String,
      default: 'text',
    },
  },
  computed: {
    rtlCSS() {
      return (this.right ? 'right' : 'left') + ' message-container'
    },
  },
}
</script>
