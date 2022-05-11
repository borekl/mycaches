<script>
  import Toggle from './Toggle.svelte';
  export let value;

  let options = [
		{ value: 0, icon: '🥇', label: 'no xTF', disabled: true },
		{ value: 1, icon: '🥇', label: 'FTF' },
		{ value: 2, icon: '🥈', label: 'STF' },
		{ value: 3, icon: '🥉', label: 'TTF' }
	];
</script>

<Toggle bind:value={value} options={options}/>
