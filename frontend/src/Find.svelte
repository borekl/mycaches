<script>

  import { prefix } from './store.js';
  import Xtf from './Xtf.svelte';
  import Gallery from './Gallery.svelte';
  import Favorite from './Favorite.svelte';
	import StatusFind from './StatusFind.svelte';
	import FiveStars from './FiveStars.svelte';
	import CacheType from './CacheType.svelte';
  import Days from './Days.svelte';
  import CacheControls from './CacheControls.svelte';

  // rowid of entry we are asked to load (special value of 'new' is passed
  // to backend which provides default entry)
  export let id;
  // reference for going back to a SSR page
  export let backref;
  // data loaded via the API
  let curr;
  // is current entry the last one?
  let is_last;
  // status message
  let status = null;
  // in progress indication
  let in_progress = false;

  // retrieve a find entry with specified row id, if id contains special value
  // of 'last' it is converted to real numerical value of the last entry
  async function retrieve() {
    if(in_progress) return;
    in_progress = true;
    try {
      const response = await fetch(`${$prefix}/api/v1/finds/${id}`, {
        cache: 'no-cache'
      });
      if(response.status == 200) {
        curr = await response.json();
        is_last = curr.last;
        id = curr.id;
      } else {
        throw `Failed to query find ${id}`;
      }
    } catch(e) {
      status = e;
    } finally {
      in_progress = false;
    }
  }

  // go to previous or first item
  function prevItem(evt) {
    let prev_id = id;
    if(evt && evt.detail.first) { id = 1 }
    else if(id > 1) { id-- }
    if(id != prev_id) retrieve();
  }

  // go to next or last item
  function nextItem(evt) {
    let prev_id = id;
    if(evt && evt.detail.last) { id = 'last' }
    else if(!is_last) { id++ }
    if(id != prev_id) retrieve();
  }

  // update current item
  async function updateCurrentItem() {
    if(in_progress) return;
    in_progress = true;
    status = 'Updating...';

    try {
      const response = await fetch(`${$prefix}/api/v1/finds/${id}`, {
        method: 'PUT',
        cache: 'no-cache',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(curr)
      });
      if(response.status == 204) {
        status = 'Updated successfully';
        in_progress = false;
        retrieve();
      } else {
        throw response.statusText;
      }
    } catch(e) {
      console.error('Error:', e);
      status = 'Error during update';
    } finally {
      in_progress = false;
    }
  }

  // save new item
  async function saveNewItem() {
    if(in_progress) return;
    in_progress = true;
    status = 'Saving new...';

    try {
      const response = await fetch(`${$prefix}/api/v1/finds`, {
        method: 'POST',
        cache: 'no-cache',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(curr)
      });
      if(response.status == 201) {
        const d = await response.json();
        id = d.id;
        in_progress = false;
        status = 'New entry saved successfully';
        retrieve();
      }
    } catch(e) {
      console.error('Error:', e);
      status = 'Error during save new';
    } finally {
      in_progress = false;
    }
  }

  // delete current item
  async function deleteItem() {
    if(in_progress) return;
    in_progress = true;
    status = 'Deleting...';
    try {
      const response = await fetch(`${$prefix}/api/v1/finds/${id}`, {
        method: 'DELETE',
        cache: 'no-cache',
      });
      if(response.status == 204) {
        status = 'Deleted successfully';
        in_progress = false;
        prevItem();
      } else {
        throw response.statusText;
      }
    } catch(e) {
      console.error('Error:', e);
      status = 'Error during delete';
    } finally {
      in_progress = false;
    }
  }

  // dispatcher
  function dispatch(e) {
    let verb = e.detail.action;
    status = null;

    switch(verb) {
      case 'prevItem': prevItem(e); break;
      case 'nextItem': nextItem(e); break;
      case 'retrieveItem': retrieve(); break;
      case 'deleteItem': deleteItem(); break;
      case 'saveItemAsNew': saveNewItem(); break;
      case 'updateItem': updateCurrentItem(); break;
      case 'exitPage': window.location.href = backref; break;
    }
  }

  // initialization code
  if(id != 'new' && id != 'last') id = parseInt(id);
  retrieve();

</script>


{#if curr}

  <div class="form">

    <div class="header">
      <CacheType size="48" bind:type={curr.ctype}/>
      <div>
        <input class="cacheid" bind:value="{curr.cacheid}" placeholder="GC code"><br>
        <input class="cname" bind:value="{curr.name}" placeholder="Cache name">
      </div>
    </div>

    <div class="info">
      {#if id}<span class="days">#{id}</span>{:else}<span>new entry</span>{/if}
      {#if curr.age} · unfound for <span class="days"><Days d="{curr.age}"/></span>{/if}
      {#if curr.held} · held for <span class="days"><Days d="{curr.held}"/></span>{/if}
    </div>

    <div class="main">
      <div class="label lbl_diff">difficulty</div>
      <div class="rating val_diff"><FiveStars bind:value="{curr.difficulty}"/></div>
      <div class="label lbl_terr">terrain</div>
      <div class="rating val_terr"><FiveStars bind:value="{curr.terrain}"/></div>
      <div class="label lbl_prev">previous find</div>
      <div class="val_prev"><input class="date" size=4 bind:value={curr.prev}></div>
      <div class="label lbl_found">my find</div>
      <div class="val_found"><input class="date" size=4 bind:value={curr.found}></div>
      <div class="label lbl_next">next find</div>
      <div class="val_next"><input class="date" size=4 bind:value={curr.next}></div>
      <div class="label lbl_status">status</div>
      <div class="val_status vcenter"><StatusFind bind:value="{curr.status}"/></div>
      <div class="label lbl_xtf">xtf</div>
      <div class="val_xtf vcenter"><Xtf bind:value={curr.xtf}/></div>
      <div class="label lbl_favorite">favorite</div>
      <div class="val_favorite vcenter"><Favorite bind:value={curr.favorite}/></div>
      <div class="label lbl_gallery">gallery</div>
      <div class="val_gallery vcenter"><Gallery bind:value={curr.gallery}/></div>
      <div class="label lbl_logid">log uuid</div>
      <div class="val_logid"><input size=40 bind:value={curr.logid}></div>
    </div>

    <CacheControls
      on:dispatch="{dispatch}"
      bind:is_last="{is_last}"
      bind:status="{status}"
      bind:id="{id}"
    />

  </div>
{/if}


<style>

	div.form {
		background-color: white;
		min-width: 40em;
		box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
	}

  /*--- header */

	div.header {
		display: flex;
		align-items: center;
		gap: 1rem;
		padding: 1em;
    background: linear-gradient(90deg, rgba(255,255,255,1) 0%, rgba(255,255,255,1) 11%, rgba(72,157,120,1) 100%);
  }
  div.header div {
    width: 100%;
  }
	div.info {
		background-color: #ded;
		padding: 1em;
    color: rgba(0,0,0,0.5);
  }
  input {
    border: none;
    color: #333;
    background: none;
    margin: 0;
    padding: 0;
    outline: none;
    width: 100%;
  }
  input::placeholder {
    color: rgba(96,96,96,0.5);
  }
	input.cacheid {
		font-size: 200%;
    font-weight: 800;
	}
	input.cname {
    color: #333;
		font-size: 150%;
	}
  span.days {
    font-weight: 700;
  }

  /*--- main */

  div.main {
		padding: 1em;
    display: grid;
    grid-template-columns: 1fr 1fr 1fr 1fr;
    grid-template-rows: repeat(6, 2rem);
    column-gap: 1rem;
    row-gap: 0.3rem;
    grid-template-areas:
      "lbl-diff val-diff lbl-prev val-prev"
      "lbl-terr val-terr lbl-found val-found"
      "lbl-xtf val-xtf lbl-next val-next"
      "lbl-favorite val-favorite . ."
      "lbl-gallery val-gallery lbl-status val-status"
      "lbl-logid val-logid val-logid val-logid";
  }

  .lbl_diff { grid-area: lbl-diff }
  .val_diff { grid-area: val-diff }
  .lbl_terr { grid-area: lbl-terr }
  .val_terr { grid-area: val-terr }
  .lbl_favorite { grid-area: lbl-favorite }
  .val_favorite { grid-area: val-favorite }
  .lbl_xtf { grid-area: lbl-xtf }
  .val_xtf { grid-area: val-xtf }
  .lbl_found { grid-area: lbl-found }
  .val_found { grid-area: val-found }
  .lbl_gallery { grid-area: lbl-gallery }
  .val_gallery { grid-area: val-gallery }
  .lbl_status { grid-area: lbl-status }
  .val_status { grid-area: val-status }
  .lbl_logid { grid-area: lbl-logid }
  .val_logid { grid-area: val-logid }

  div.main input { font-size: 133%; }
  div.main .vcenter { align-self: center; }
  div.main .label { font-weight: bold; text-align: right; align-self: center; }
  .rating { font-size: 133%; }

  /*--- controls */

  </style>
