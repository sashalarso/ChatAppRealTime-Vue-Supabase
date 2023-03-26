<script setup>
import { defineComponent } from "vue";

defineComponent({
  name: "App",
});
</script>

<template lang="pug">
router-view(:key="$route.fullPath")
</template>
