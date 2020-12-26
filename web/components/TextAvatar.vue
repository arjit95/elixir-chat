<template>
  <v-avatar :color="color" :size="size" :left="left">
    <v-img :src="profile">
      <template v-slot:placeholder>
        <v-row class="fill-height ma-0" align="center" justify="center">
          <span class="white--text" :style="{ fontSize: fontSize }">{{
            displayName
          }}</span>
        </v-row>
      </template>
    </v-img>
  </v-avatar>
</template>
<script>
export default {
  name: 'TextAvatar',
  props: {
    profile: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
    size: {
      type: Number,
      default: 128,
    },
    left: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      colors: [
        '#b71c1c',
        '#d32f2f',
        '#d81b60',
        '#7b1fa2',
        '#512da8',
        '#546e7a',
        '#bb4d00',
        '#387002',
        '#00701a',
        '#004d40',
      ],
    }
  },
  computed: {
    color() {
      return this.colors[this.displayName.charCodeAt(0) % this.colors.length]
    },

    displayName() {
      return (this.name?.substring(0, 1) || 'p').toUpperCase()
    },
    fontSize() {
      return this.size / 2.5 + 'px'
    },
  },
}
</script>
