<script>
  import Toggle from './Toggle.svelte';
  export let value;

  let options = [
		{ value: 1, icon: '☀️', label: 'active' },
		{ value: 6, icon: '🗑️', label: 'archived' }
	];
</script>

<Toggle bind:value={value} options={options}/>
