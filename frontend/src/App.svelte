<script>

  import { prefix } from './store.js';
  import Find from './Find.svelte';

  let
	  main = document.getElementById('app'),
	  type = main.getAttribute('data-type'),
	  id = main.getAttribute('data-id'),
		prefix_src = main.getAttribute('data-prefix');

	if(prefix_src == '/') prefix_src = '';
	prefix.set(prefix_src);

</script>

{#if type == 'find'}<Find id={id} prefix={prefix}/>{/if}
