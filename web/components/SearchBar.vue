<template>
  <v-scale-transition origin="right center 0">
    <v-autocomplete
      v-model="model"
      :loading="isLoading"
      :items="searchResults"
      :search-input.sync="search"
      flat
      hide-details
      label="Search..."
      solo-inverted
      hide-no-data
      item-text="name"
      item-value="username"
      return-object
      dense
      class="autocomplete"
    >
      <template v-slot:item="{ item }">
        <v-list-item-avatar>
          <text-avatar :name="item.name" :size="24" />
        </v-list-item-avatar>
        <v-list-item-content @click="select(item)">
          <v-list-item-title class="search-title">{{
            item.name
          }}</v-list-item-title>
          <v-list-item-subtitle> @{{ item.username }} </v-list-item-subtitle>
        </v-list-item-content>
      </template>
    </v-autocomplete>
  </v-scale-transition>
</template>

<script>
const debounce = function (fn, timeout = 1000) {
  let timer = null
  let inProgress = false
  return function () {
    if (inProgress) {
      return
    }

    if (timer) {
      clearTimeout(timer)
    }

    const self = this
    const args = arguments

    timer = setTimeout(async function () {
      inProgress = true
      await fn.apply(self, args)
      inProgress = false
    }, timeout)
  }
}

export default {
  data() {
    return {
      search: null,
      model: null,
      isLoading: false,
      searchResults: [],
    }
  },
  watch: {
    search: debounce(async function (val) {
      if (val.length <= 3 || this.isLoading || val === this.model?.name) {
        return
      }

      this.isLoading = true
      const response = await this.$sdk.User.search(val)
      this.isLoading = false
      if (response.error) {
        // handle error
      }

      this.searchResults = response.results.map(({ username, name }) => ({
        username,
        name,
        type: 'user',
      }))
    }),
  },
  methods: {
    select(val) {
      if (!val?.username) {
        return
      }

      this.$emit('select', {
        title: val.name,
        subtitle: val.username,
        id: val.username,
      })
    },
  },
}
</script>
