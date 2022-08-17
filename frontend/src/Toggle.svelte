<!--
  Toggle UI element

  User interface element that cycles between two or more labels. The labels,
  values etc. are defind in the options array. Each element of the options
  array is a hash with following keys:

   - value, this is returned in the 'value' prop
   - icon, string shown to the user
   - label, optional short description string only shown on hover
   - disabled, boolean, if true, the icon and label are shown grayed out

  This component is meant to be used as a base for actual UI elements
-->

<script>
  export let value, options;
  let n; // position in the options array

  // based on supplied 'value' prop find option entry with index 'n'
  $: {
    for(let i = 0; i < options.length; i++) {
      if(options[i].value == value) { n = i; break; }
    }
    if(typeof n == 'undefined') throw Error('Unknown value: ' + value);
  }

  // cycling function, get and apply the next option
  function toggle() {
    n++;
    if(n >= options.length) n = 0;
    value = options[n].value;
  }
</script>

<span
  on:click={toggle} class="toggle"
  class:disabled="{('disabled' in options[n]) && options[n].disabled}"
>{options[n].icon}
  {#if 'label' in options[n]}
  <span class="label">{options[n].label}</span>
  {/if}
</span>

<style>
  .toggle {
    position: relative;
    user-select: none;
    cursor: pointer;
  }
  .toggle .label {
    background-color: rgba(255,255,255,0.6);
    position: absolute;
    display: none;
    left: 1.5em;
    padding: 0 0.3em;
    width: 10em;
  }
  .toggle:hover .label { display: inline; }
  .disabled {
    filter: grayscale(1) opacity(30%);
  }
</style>
