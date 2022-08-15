<script>

  import { prefix } from './store.js';
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();

  export let question;
  export let activator;

</script>

<div class="yesno">

  <div class="question">{question}</div>

  <button class="cancel" on:click="{() => activator = false}"
  ><img src="{$prefix}/cross.svg" alt="Cancel"
  ></button>

  <button class="proceed" on:click="{() => dispatch('proceed')}"
  ><img src="{$prefix}/check.svg" alt="Proceed"
  ></button>

</div>


<style>
  div.yesno {
    background-color: #dbb;
    display: flex;
    padding: 1em;
    justify-content: center;
    align-items: center;
    gap: 0.5em;
  }

  button {
    cursor: pointer;
    border: none;
    background: #eee;
    padding: 0.3em 0.7em;
  }
  button.proceed {
    background-color: #f99;
  }
  button.cancel {
    background-color: #9d9;
  }
  button img {
    width: 1em;
    vertical-align: sub;
    opacity: 0.3;
  }

</style>
