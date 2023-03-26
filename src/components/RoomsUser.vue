<script setup>
import { defineComponent, ref, onMounted } from "vue";
import useAuthUser from "src/composables/UseAuthUser";
import useSupabase from "src/boot/supabase";
import { useRouter } from "vue-router";

defineComponent({
  name: "RoomsUser",
});
const { user } = useAuthUser();
const { supabase } = useSupabase();
const router = useRouter();

onMounted(() => {
  if (user._rawValue != null) {
    get_rooms(user._rawValue.email);
  }
});

const my_rooms = ref([]);
const emails = ref([]);
const my_email = user._rawValue.email;
const usernames = ref([]);

const listen_new = supabase.from("messages").on("INSERT", (payload) => {
  for (let i = 0; i < usernames.value.length; i++) {
    if (payload.new["room"] == usernames.value[i][0].id) {
      const ddate = new Date(payload.new["created_at"]);
      usernames.value[i][0].last_message = payload.new["message"];
      usernames.value[i][0].last_date =
        ddate.getHours() + ":" + ddate.getMinutes();
    }
  }
});

async function new_room(my_email, guest_email) {
  const { data } = supabase
    .from("rooms")
    .insert({ owner: my_email, guest: guest_email })
    .select();
}
async function get_rooms(my_email) {
  const { data } = await supabase
    .from("rooms")
    .select("members")
    .contains("members", [my_email]);

  if (data) {
    for (let i = 0; i < data.length; i++) {
      for (let j = 0; j < data[i].members.length; j++) {
        if (data[i].members[j] != my_email) {
          emails.value.push(data[i].members[j]);
        }
      }
    }
  }
  const ids = ref([]);
  for (let i = 0; i < emails.value.length; i++) {
    const { data } = await supabase
      .from("profiles")
      .select("username,pp")
      .match({ email: emails.value[i] });

    usernames.value.push(data);
    const test = await supabase
      .from("rooms")
      .select("id")
      .contains("members", [user._rawValue.email, emails.value[i]]);

    ids.value.push(test.data[0].id);
  }
  console.log(ids.value);
  for (let i = 0; i < usernames.value.length; i++) {
    usernames.value[i][0].id = ids.value[i];
  }
  for (let i = 0; i < usernames.value.length; i++) {
    const { data } = await supabase
      .from("messages")
      .select("message,created_at")
      .match({ room: usernames.value[i][0].id })
      .order("created_at", { ascending: false })
      .limit(1);
    usernames.value[i][0].last_message = data[0].message;
    const ddate = new Date(data[0].created_at);
    usernames.value[i][0].last_date =
      ddate.getHours() + ":" + ddate.getMinutes();
  }
  console.log(usernames.value);
}

function gotoroom(id) {
  router.push(`/room/${id}`);
}
</script>

<template lang="pug">
q-page(style="background-color: white;")
  div(v-for="user in usernames")
      div(@click="gotoroom(user[0].id)")
        q-item(class="card" )
          q-item-section(avatar)
            q-avatar()
              img(:src="user[0].pp")
          q-item-section
            div(class="row")
              q-item-label(style="font-size:20px" class="col" )  {{ user[0].username }}
              q-item-label(class="col" style="margin-right: 10px; margin-top: 15px;").absolute-right {{ user[0].last_date }}
            q-item-label {{user[0].last_message}}

</template>

<style>
.card:hover {
  background-color: aquamarine;
}
</style>
