<script setup>
import { defineComponent, ref } from "vue";
import { onMounted } from "vue";

import useAuthUser from "src/composables/UseAuthUser";
import useSupabase from "src/boot/supabase";
import { useRouter } from "vue-router";
import { useRoute } from "vue-router";
import { scroll } from "quasar";
import RoomsUser from "src/components/RoomsUser.vue";
const {
  getVerticalScrollPosition,
  getScrollTarget,
  setVerticalScrollPosition,
} = scroll;

defineComponent({
  name: "RoomPage",
});
const router = useRouter();
const route = useRoute();
const { user } = useAuthUser();
const me = user._rawValue.email;
onMounted(() => {
  get_messages(route.params.id);
  get_profile(me);
  get_other_profile(route.params.id);
  get_last_seen();
});

const { supabase } = useSupabase();
const messages = ref([]);
const my_message = ref("");
const senders = ref([]);
const last_seen = ref(Date);
const last_seen_render = ref("");

const listen_new = supabase
  .from("messages")
  .on("INSERT", (payload) => {
    if (payload.new["room"] == route.params.id) {
      const timestampz = payload.new["created_at"];
      payload.new["created_at"] =
        new Date(timestampz).getHours() +
        ":" +
        new Date(timestampz).getMinutes();
      messages.value.push({
        message: payload.new["message"],
        sender: payload.new["sender"],
        created_at: payload.new["created_at"],
      });
    }
  })

  .subscribe();
const listen_last_seen = supabase
  .from("profiles")
  .on("UPDATE", (payload) => {
    if (payload["new"].email == other_email.value) {
      last_seen.value = new Date(payload["new"].last_seen);
      format_date(last_seen.value);
    }
  })
  .subscribe();

async function send_message(message) {
  if (message.replace(/\s/g, "").length) {
    const { data } = await supabase
      .from("messages")
      .insert({
        message: message,
        sender: user._rawValue.email,
        room: route.params.id,
      })
      .select();
  }

  my_message.value = "";
}
async function get_messages(id) {
  const { data } = await supabase
    .from("messages")
    .select("message, sender,created_at")
    .match({ room: id })
    .order("created_at", { ascending: true });

  for (let i = 0; i < data.length; i++) {
    messages.value.push(data[i]);
    const timestampz = messages.value[i].created_at;
    messages.value[i].created_at =
      new Date(timestampz).getHours() + ":" + new Date(timestampz).getMinutes();
  }
  console.log(messages.value);
  await supabase
    .from("profiles")
    .update({ last_seen: new Date() })
    .match({ email: user._rawValue.email });
}

const username = ref("");
const pp = ref("");
async function get_profile(my_email) {
  const { data } = await supabase
    .from("profiles")
    .select("username,pp")
    .match({ email: my_email });
  console.log(data);
  username.value = data[0].username;
  pp.value = data[0].pp;
}
const other_email = ref("");
const other_pp = ref("");
const other_username = ref("");
async function get_other_profile(id) {
  const { data } = await supabase
    .from("rooms")
    .select("members")
    .match({ id: id });
  const emails = data[0].members;
  for (let i = 0; i < emails.length; i++) {
    if (emails[i] != user._rawValue.email) {
      other_email.value = emails[i];
    }
  }
  const my_data = await supabase
    .from("profiles")
    .select("last_seen")
    .match({ email: other_email.value });

  last_seen.value = new Date(my_data.data[0].last_seen);

  const today = new Date();

  if (last_seen.value.getDay() == today.getDay()) {
    last_seen_render.value =
      "en ligne aujourd'hui à " +
      last_seen.value.getHours() +
      ":" +
      last_seen.value.getMinutes();
  } else {
    last_seen_render.value =
      "en ligne le " +
      last_seen.value.getDate() +
      "/" +
      (last_seen.value.getMonth() + 1) +
      "/" +
      last_seen.value.getFullYear() +
      " à " +
      last_seen.value.getHours() +
      ":" +
      last_seen.value.getMinutes();
  }

  const test = await supabase
    .from("profiles")
    .select("username,pp")
    .match({ email: other_email.value });
  other_pp.value = test.data[0].pp;
  other_username.value = test.data[0].username;
  console.log(other_email.value);
}
const n = 0;
async function get_last_seen() {}
function format_date(date) {
  const today = new Date();
  console.log(date);
  if (date.getDay() == today.getDay()) {
    console.log("test");
    last_seen_render.value =
      "en ligne aujourd'hui à " + date.getHours() + ":" + date.getMinutes();
  }
}
const prompt = ref(false);
const new_conv = ref("");
const first_message = ref("");
async function create_conv(username, message) {
  const resp = await supabase
    .from("profiles")
    .select("email")
    .match({ username: username });
  const email = resp.data[0].email;
  const { data } = await supabase
    .from("rooms")
    .insert({ members: [email, user._rawValue.email] });
  const new_id = data[0].id;
  const test = await supabase
    .from("messages")
    .insert({ message: message, sender: user._rawValue.email, room: new_id });
  router.push(`/room/${new_id}`);
}
function isImage(url) {
  return /\.(jpg|jpeg|png|webp|avif|gif|svg)$/.test(url);
}
</script>

<template lang="pug">
div(style="background-color: white;")
  body(style="overflow-y: hidden; height: 100%; ")
    q-layout(style="min-height: 800px;").q-m-a-md

      div(s class="row justify-center")
        div(style="background-color: red; " class="col-3")
          div(style="background-color: gainsboro; height: 56px; width: auto;" class="row")
            div(class="col")
              q-avatar(style="margin-left: 5px; margin-top: 3px;")
                img(:src="pp")
            div(class="col" style="text-align: right;")
              q-btn(rounded icon="message" @click="prompt=true" style="margin-right: 20px; margin-top: 8px;")
              q-dialog(v-model="prompt" )
                q-card
                  q-card-section Entrez le nom d'utilisateur du destinataire
                  q-card-section
                    q-input(dense ,@keyup-enter="prompt=false",v-model="new_conv")
                  q-card-section Votre message
                  q-card-section
                    q-input(dense, v-model="first_message" )
                  q-card-actions(align="right")
                    q-btn(flat,label="Annuler",v-close-popup)
                    q-btn(flat,label="Envoyer",v-close-popup,@click="create_conv(new_conv,first_message)")
          q-scroll-area(style="height: 100%; max-width: 100%; width: auto;")
            RoomsUser

        div(class="col-7" style="")
          q-scroll-area(style="height: 800px; max-width: 100%; " ref="test" )
            div(class="bg-brown-2  ",style="  background-color: aqua; min-height: 650px; ").q-px-xl
              div(style="height: 70px;")
              p(v-for="message in messages" class="row")
                p(v-if="me==message.sender" class="col")
                  q-chat-message(:text="[message.message]",sent,:stamp="message.created_at")
                p(v-if="me!=message.sender",color="light-green-10" class=".col")
                  q-chat-message(:text="[message.message]",:stamp="message.created_at")
            div(class="row justify-center" style="")
              q-input(id="my_input" style=" width: 800px;" v-model="my_message" placeholder="Taper un message" rounded outlined  @keyup.enter="send_message(my_message)" )
              q-btn(rounded icon="send" @click="send_message(my_message)" id="bottom")
            q-page-sticky(position="top" style="" )
              div(style=" background-color:aquamarine; width: 100%; ")
                q-item(style=" margin-left: 10px;")
                  q-item-section(avatar)
                    q-avatar
                      img(:src="other_pp")
                  q-item-section
                    q-item-label {{ other_username }}
                    q-item-label {{ last_seen_render }}
</template>
