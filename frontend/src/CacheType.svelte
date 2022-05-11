<script>
  import CacheIcon from './CacheIcon.svelte';
  export let type;
  let show = false;

  function togglePopup() {
    show = !show;
  }

  function handleUserSelection(e) {
    const el = e.target;
    const tag = el.tagName.toUpperCase();
    let use;

    if(tag == 'USE') use = el;
    if(tag == 'SPAN') use = el.children.item(0).children.item(0);

    if(use) {
      type = use.getAttribute('xlink:href').match(/(\d+)$/)[1];
      show = false;
    }

    e.stopPropagation()
  }
</script>

<span on:click="{togglePopup}">
<CacheIcon type={type}/>
</span>

{#if show}
<div class="popup" on:click="{togglePopup}" style:display="{show ? 'block':'none'}">

  <div class="cachetypes" on:click="{e => e.stopPropagation()}">

    <div on:click="{handleUserSelection}">
      <span class="cachetype"><CacheIcon type=2/> traditional cache</span>
      <span class="cachetype"><CacheIcon type=3/> multicache</span>
      <span class="cachetype"><CacheIcon type=8/> unknown cache</span>
      <span class="cachetype"><CacheIcon type=137/> Earth cache</span>
      <span class="cachetype"><CacheIcon type=4/> virtual cache</span>
      <span class="cachetype"><CacheIcon type=1858/> Wherigo cache</span>
      <span class="cachetype"><CacheIcon type=5/> letterbox hybrid</span>
      <span class="cachetype"><CacheIcon type=11/> webcam cache</span>
      <span class="cachetype"><CacheIcon type=12/> locationless cache</span>
      <span class="cachetype"><CacheIcon type=9/> Project APE cache</span>
    </div>

    <div on:click="{handleUserSelection}">
      <span class="cachetype"><CacheIcon type=13/> CITO</span>
      <span class="cachetype"><CacheIcon type=6/> event</span>
      <span class="cachetype"><CacheIcon type=453/> mega event</span>
      <span class="cachetype"><CacheIcon type=7005/> giga event</span>
      <span class="cachetype"><CacheIcon type=3653/> Community Celebration Event</span>
      <span class="cachetype"><CacheIcon type=1304/> GPS Adventures Exhibit</span>
      <span class="cachetype"><CacheIcon type=3773/> Geocaching HQ</span>
      <span class="cachetype"><CacheIcon type=3774/> Geocaching HQ Celebration</span>
      <span class="cachetype"><CacheIcon type=4738/> Geocaching HQ Block Party</span>
    </div>

  </div>

</div>
{/if}

<style>

  .popup {
    justify-content: center;
    align-items: center;
    position: fixed;
    top: 0;
    bottom: 0;
    left: 0;
    right: 0;
    background: rgba(0, 0, 0, 0.7);
    z-index: 5;
    display: flex;
  }

  .cachetypes {
    display: inline-flex;
    border: 4px solid #888;
    background-color: white;
  }

  .cachetypes div {
    display: flex;
    flex-direction: column;
    padding: 2rem;
  }

  .cachetypes div span {
    margin: 0.5rem;
  }

  .cachetype {
    user-select: none;
  }

  </style>
