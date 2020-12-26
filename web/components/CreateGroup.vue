<template>
  <v-row justify="center">
    <v-list-item :ripple="false" @click.stop="open()">
      <slot name="icon"></slot>
    </v-list-item>

    <v-dialog
      v-model="dialog"
      fullscreen
      hide-overlay
      transition="dialog-bottom-transition"
    >
      <v-card>
        <v-toolbar dark color="primary">
          <v-btn icon dark @click="close()">
            <v-icon>mdi-close</v-icon>
          </v-btn>
          <v-toolbar-title>{{
            supportedOperations[operation].title
          }}</v-toolbar-title>
          <v-spacer></v-spacer>
        </v-toolbar>
        <v-form ref="form" v-model="valid" lazy-validation class="mt-4 ms-2">
          <v-row no-gutters>
            <v-col cols="5">
              <v-text-field
                v-model="name"
                :counter="40"
                :rules="nameRules"
                label="Group Name"
                required
                outlined
                shaped
                :disabled="disabled"
              ></v-text-field>
            </v-col>
          </v-row>
          <v-row no-gutters>
            <v-col cols="8">
              <v-autocomplete
                v-model="members.model"
                :items="contacts"
                filled
                chips
                color="blue-grey lighten-2"
                label="Members"
                multiple
                deletable-chips
                :rules="members.rules"
              >
                <template v-slot:selection="data">
                  <v-chip
                    v-bind="data.attrs"
                    :input-value="data.selected"
                    close
                    @click="data.select"
                    @click:close="remove(data.item)"
                  >
                    <text-avatar :size="16" :name="data.item" left />
                    {{ data.item }}
                  </v-chip>
                </template>
                <template v-slot:item="data">
                  <template v-if="typeof data.item !== 'object'">
                    <v-list-item-content
                      v-text="data.item"
                    ></v-list-item-content>
                  </template>
                  <template v-else>
                    <v-list-item-avatar>
                      <text-avatar :size="36" :name="data.item" />
                    </v-list-item-avatar>
                    <v-list-item-content class="ms-2">
                      <v-list-item-title>{{ data.item }}</v-list-item-title>
                    </v-list-item-content>
                  </template>
                </template>
              </v-autocomplete>
            </v-col>
          </v-row>
          <v-row no-gutters>
            <v-btn class="ma-2" color="primary" @click="submit()">
              {{ supportedOperations[operation].title }}
              <template v-slot:loader>
                <span class="custom-loader">
                  <v-icon>mdi-cached</v-icon>
                </span>
              </template>
            </v-btn>
          </v-row>
        </v-form>
      </v-card>
    </v-dialog>
  </v-row>
</template>

<style lang="scss" scoped>
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
.custom-loader {
  animation: loader 1s infinite;
  display: flex;
}

@-moz-keyframes loader {
  from {
    transform: rotate(0);
  }
  to {
    transform: rotate(360deg);
  }
}
@-webkit-keyframes loader {
  from {
    transform: rotate(0);
  }
  to {
    transform: rotate(360deg);
  }
}
@-o-keyframes loader {
  from {
    transform: rotate(0);
  }
  to {
    transform: rotate(360deg);
  }
}
@keyframes loader {
  from {
    transform: rotate(0);
  }
  to {
    transform: rotate(360deg);
  }
}
</style>

<script>
import TextAvatar from '~/components/TextAvatar'

export default {
  components: {
    TextAvatar,
  },
  props: {
    group: {
      type: Object,
      default: null,
    },
    opened: {
      type: Boolean,
      default: false,
    },
    operation: {
      // 0: Create, 1: Kick Member, 2 Invite member
      type: Number,
      default: 0,
    },
    contacts: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      dialogModel: false,
      valid: false,
      defaultName: '',
      nameRules: [
        (v) => !!v || 'Name is required',
        (v) => (v && v.length >= 4) || 'Name must be more than 3 characters',
      ],
      members: {
        model: [],
        search: null,
        rules: [(v) => v.length >= 1 || 'Must have at least 1 member'],
      },
      supportedOperations: [
        {
          title: 'Create Group',
          operation: 'create',
        },
        {
          title: 'Kick Member',
          operation: 'kick',
        },
        {
          title: 'Invite Member',
          operation: 'invite',
        },
      ],
    }
  },

  computed: {
    name: {
      get() {
        return this.group?.info.name || this.defaultName
      },
      set(val) {
        this.defaultName = val
      },
    },
    disabled() {
      return !!this.group
    },
    dialog: {
      get() {
        return this.opened || this.dialogModel
      },
      set(val) {
        this.dialogModel = val
      },
    },
  },
  watch: {
    opened(val) {
      if (!val) {
        this.dialogModel = val
      }
    },
  },
  methods: {
    open() {
      this.dialog = true
      this.$emit('open', this.operation)
    },

    close() {
      this.$refs.form?.reset()
      this.$emit('close')
      this.$nextTick(() => {
        if (this.dialogModel) {
          this.dialogModel = false
        }
      })
    },

    remove(item) {
      const index = this.members.model.indexOf(item)
      if (index >= 0) this.members.model.splice(index, 1)
    },

    submit() {
      if (!this.$refs.form?.validate()) {
        return
      }

      const { operation } = this.supportedOperations[this.operation]
      this.$emit(operation, {
        members: this.members.model,
        name: this.defaultName || this.group?.info.name,
      })

      this.close()
    },
  },
}
</script>
