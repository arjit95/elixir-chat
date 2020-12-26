<template>
  <!--- Header -->
  <v-container class="empty-container" fluid>
    <v-row class="centered" no-gutters>
      <v-icon size="600%"> mdi-chat-plus-outline </v-icon>
      Start a conversation by selecting a chat or use the search bar above
    </v-row>
  </v-container>
</template>

<style scoped>
.empty-container {
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  flex-direction: column;
}

.centered {
  display: flex;
  align-items: center;
  flex-direction: column;
  flex: 0 1 auto;
}
</style>

<script>
export default {
  name: 'EmptyConversation',
}
</script>
