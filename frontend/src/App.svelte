<script>

  import { prefix } from './store.js';
  import Find from './Find.svelte';
  import Hide from './Hide.svelte';

  let
	  main = document.getElementById('app'),
	  type = main.getAttribute('data-type'),
	  id = main.getAttribute('data-id'),
		prefix_src = main.getAttribute('data-prefix'),
		backref = main.getAttribute('data-backref');

	if(prefix_src == '/') prefix_src = '';
	prefix.set(prefix_src);

</script>

{#if type == 'find'}<Find id={id} backref={backref}/>{/if}
{#if type == 'hide'}<Hide id={id} backref={backref}/>{/if}
