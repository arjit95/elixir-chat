<template>
  <v-app dark>
    <nuxt />
  </v-app>
</template>

<style scoped>
#main-container {
  padding: 0;
}
</style>
<style>
html {
  overflow-y: hidden !important;
}
</style>
<script>
export default {
  data() {
    return {
      clipped: false,
      drawer: false,
      fixed: false,
      items: [
        {
          icon: 'mdi-apps',
          title: 'Welcome',
          to: '/',
        },
        {
          icon: 'mdi-chart-bubble',
          title: 'Inspire',
          to: '/inspire',
        },
      ],
      miniVariant: false,
      right: true,
      title: 'Vuetify.js',
    }
  },
}
</script>
