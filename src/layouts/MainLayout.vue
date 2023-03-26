<script setup>
import { defineComponent } from "vue";
import TechStackLinks from "src/components/TechStackLinks.vue";
import RoutingTabs from "src/components/RoutingTabs.vue";

defineComponent({ name: "MainLayout" });
</script>

<template lang="pug">
q-layout(view="hHh lpR fFf")
  q-header.bg-purple-9(elevated)
    q-toolbar.q-pa-lg.text-h4.justify-between.items-center

      span.text-h6.text-weight-medium.flex.flex-center
        span.text-yellow-2 The Counter-Adder
        span.q-mx-sm.row
          .huggyBearFont.text-italic.text-h4.text-blue-3 QUASA
          .huggyBearFont.text-italic.text-h4.text-teal-2 BASE
        span.text-yellow-2 full-stack starter app
      RoutingTabs
  q-page-container
    router-view
</template>
