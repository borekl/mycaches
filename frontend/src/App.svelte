<script>
  import Xtf from './Xtf.svelte';
  import Gallery from './Gallery.svelte';
  import Favorite from './Favorite.svelte';
	import StatusFind from './StatusFind.svelte';
	import FiveStars from './FiveStars.svelte';
	import CacheType from './CacheType.svelte';

  let
	  main = document.getElementById('app'),
	  type = main.getAttribute('data-type'),
	  id = main.getAttribute('data-id'),
    url = `/api/v1/${type}s/${id}`,
		data;

	fetch(url, { cache: 'no-cache' })
	.then(response => {
    if(response.status == 200) return response.json();
		else throw new Error('Failed to talk to backend');
	}).then(d => data = d);

</script>

<p>Type: {type}<br>
Id: {id}<br>
API call: {url}</p>

{#if data}
  {#if type == 'find'}
		<table class="entry">
			<tr><td>Id:</td><td>{id}</td></tr>
			<tr><td>Cache id:</td><td>{data.cacheid}</td></tr>
			<tr><td>Name:</td><td>{data.name}</td></tr>
			<tr><td>Cache type:</td><td><CacheType bind:type={data.ctype}/></td></tr>
			<tr><td>Difficulty:</td><td><FiveStars bind:value={data.difficulty}/> {data.difficulty}</td></tr>
			<tr><td>Terrain:</td><td><FiveStars bind:value={data.terrain}/> {data.terrain}</td></tr>
			<tr><td>Previous find:</td><td>{data.prev}</td></tr>
			<tr><td>Found date:</td><td>{data.found}</td></tr>
			<tr><td>Next find:</td><td>{data.next}</td></tr>
			<tr><td>Status:</td><td><StatusFind bind:value={data.status}/></td></tr>
			<tr><td>Xtf:</td><td><Xtf bind:value={data.xtf}/></td></tr>
			<tr><td>Gallery:</td><td><Gallery bind:value={data.gallery}/></td></tr>
			<tr><td>Favorite:</td><td><Favorite bind:value={data.favorite}/></td></tr>
			<tr><td>Log uuid:</td><td>{data.logid}</td></tr>
		</table>
	{/if}
{/if}


<style>
	table { border-collapse: collapse; }
	table.entry td { border: 1px black solid; padding: 0.5em }
</style>
