<!--
  Controls (ie. buttons and associated machinery) for the finds/hides form.
-->

<script>

  import { prefix } from './store.js';
  import CtrlYesNo from './CtrlYesNo.svelte';
  import { createEventDispatcher } from 'svelte';
  const dispatch = createEventDispatcher();

  // flag indicating that the current entry is the last one (and therefore user
  // cannot advance to the next one etc.)
  export let is_last;

  // status message (user feedback after saving/deleting)
  export let status;

  // state variable for the yes/no confirmation subdialog
  let yesno = false;

  // state of the shift key (true when pressed), used as modifier for the "Save"
  // operation
  let shift = false;

  // functions to go to the previous/next/first/last item
  function prevItem(evt) {
    dispatch('dispatch', {
      action: 'prevItem',
      first: evt.shiftKey
    })
  }
  function nextItem(evt) {
    dispatch('dispatch', {
      action: 'nextItem',
      last: evt.shiftKey
    })
  }

  // reload item
  function retrieveItem() {
    dispatch('dispatch', { action: 'retrieveItem'} )
  }

  // save or update current item
  function saveOrUpdateItem() {
    if(shift) {
      dispatch('dispatch', { action: 'saveItemAsNew' });
    } else {
      dispatch('dispatch', { action: 'updateItem' });
    }
  }

  // delete item
  function deleteItem() {
    yesno = false;
    dispatch('dispatch', { action: 'deleteItem'});
  }

  // functions for tracking shift key state
  function keyDown(evt) {
    if(evt.code == 'ShiftLeft' || evt.code == 'ShiftRight') {
      shift = true;
    }
  }
  function keyUp(evt) {
    if(evt.code == 'ShiftLeft' || evt.code == 'ShiftRight') {
      shift = false;
    }
  }

</script>

<svelte:window on:keydown="{keyDown}" on:keyup="{keyUp}" />

{#if !yesno}
<div class="controls">

  <!-- left side buttons -->

  <div>
    <button on:click="{prevItem}"
    ><img class="rotleft" src="{$prefix}/pyramid.svg" alt="Previous"
    ></button>

    <button on:click="{nextItem}"
      class:disabled="{is_last}"
    ><img class="rotright" src="{$prefix}/pyramid.svg" alt="Next"
    ></button>

    <button on:click="{retrieveItem}"
    ><img src="{$prefix}/rotate-right.svg" alt="Reload"
    ></button>
  </div>

  <!-- optional center status message -->

  {#if status}
  <div class="status" on:click="{() => status = null}">{status}</div>
  {/if}

  <!-- right side buttons -->

  <div>

    {#if is_last}
    <button class="trash" on:click="{() => yesno = true}"
    ><img src="{$prefix}/trash.svg" alt="Delete"
    ></button>
    {/if}

    <button
      class="cancel"
      on:click="{() => dispatch('dispatch', { action: 'exitPage'})}"
    ><img src="{$prefix}/cross.svg" alt="Cancel"
    ></button>

    <button
      class:save="{!shift}"
      class:savenew="{shift}"
      on:click="{saveOrUpdateItem}"
    >{#if shift}<img src="{$prefix}/add-document.svg" alt="Save">
    {:else}<img src="{$prefix}/check.svg" alt="Save">{/if}
    </button>

  </div>

</div>
{:else}
<CtrlYesNo
  on:proceed="{deleteItem}"
  bind:activator="{yesno}"
  question="Are you sure to delete this cache?"
/>
{/if}


<style>

  div.controls {
    background-color: #ddd;
    display: flex;
    padding: 1em;
    justify-content: space-between;
    align-items: center;
  }

  div.controls div {
    display: flex;
    gap: 0.5em;
  }

  div.status {
    cursor: pointer;
  }

  button {
    cursor: pointer;
    border: none;
    background: #eee;
    padding: 0.3em 0.7em;
  }
  button.save {
    background-color: #ada;
  }
  button.savenew {
    background-color: #cc8;
  }
  button.cancel {
    background-color: rgb(183, 185, 209);
  }
  button.trash {
    background-color: #daa;
  }
  button img {
    width: 1em;
    vertical-align: sub;
    opacity: 0.3;
  }
  button.disabled img {
    opacity: 0.1;
  }
  button:hover img {
    width: 1em;
    vertical-align: sub;
    opacity: 0.6;
  }
  button.disabled:hover img {
    opacity: 0.1;
  }
  .rotright {
    transform: rotate(90deg);
  }
  .rotleft {
    transform: rotate(-90deg);
  }

</style>
