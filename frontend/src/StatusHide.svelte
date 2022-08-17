<script>
  import Toggle from './Toggle.svelte';
  export let value;

  let options = [
    { value: 0, icon: '⚠️', label: 'undefined' },
		{ value: 1, icon: '☀️', label: 'active' },
    { value: 2, icon: '⛅', label: 'disabled' },
    { value: 3, icon: '✏️', label: 'in development' },
    { value: 4, icon: '⛏️', label: 'to be placed' },
    { value: 5, icon: '🏁', label: 'wait for publication' },
		{ value: 6, icon: '🗑️', label: 'archived' }
	];
</script>

<Toggle bind:value={value} options={options}/>
