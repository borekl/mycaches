<script>
  import Toggle from './Toggle.svelte';
  export let value;

	let options = [
		{ value: 0, icon: '📷', disabled: true },
		{ value: 1, icon: '📷' }
  ];
</script>

<Toggle bind:value={value} options={options}/>
