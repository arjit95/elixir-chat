<template>
  <v-toolbar color="primary">
    <v-app-bar-nav-icon>
      <text-avatar :size="42" :name="title" />
    </v-app-bar-nav-icon>

    <v-toolbar-title>
      <div class="text-body-1">{{ title }}</div>
      <div class="text-caption">{{ subtitle }}</div>
    </v-toolbar-title>

    <v-spacer></v-spacer>
    <v-menu left bottom>
      <template v-slot:activator="{ on, attrs }">
        <v-btn icon v-bind="attrs" v-on="on">
          <v-icon>mdi-dots-vertical</v-icon>
        </v-btn>
      </template>

      <v-list>
        <v-list-item v-for="n in toolbarLinks" :key="n.title">
          <v-list-item-title @click="n.onclick()">{{
            n.title
          }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-menu>
  </v-toolbar>
</template>

<script>
import TextAvatar from '~/components/TextAvatar'
export default {
  components: {
    TextAvatar,
  },
  props: {
    title: {
      type: String,
      default: '',
    },
    subtitle: {
      type: String,
      default: '',
    },
    view: {
      type: String,
      default: 'user',
    },
  },
  data() {
    const isSuperUser = () => {
      const username = this.$sdk.Connection.username
      return (
        this.view === 'group' &&
        this.$sdk.Managers.Groups.active.info.admin === username
      )
    }

    return {
      links: {
        group: [
          {
            title: 'Invite',
            onclick: () => this.$emit('invite'),
            canShow: isSuperUser,
          },
          {
            title: 'Kick Member(s)',
            onclick: () => this.$emit('kick'),
            canShow: isSuperUser,
          },
          {
            title: 'Delete Group',
            onclick: () => this.$emit('delete'),
            canShow: isSuperUser,
          },
          {
            title: 'Exit Group',
            onclick: () => this.$emit('exit'),
            canShow: () => true,
          },
        ],
        user: [
          // {
          //   title: 'Block',
          //   onclick: () => this.$emit('block'),
          //   canShow: () => true,
          // },
        ],
      },
    }
  },
  computed: {
    toolbarLinks() {
      return this.links[this.view].filter(({ canShow }) => canShow())
    },
  },
}
</script>
