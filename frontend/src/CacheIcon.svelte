<script>
  import { prefix } from './store.js';
  export let type;
  export let size = 32;
</script>

<svg height="{size}" width="{size}"><use xlink:href="{$prefix}/cache-types.svg#icon-{type}"></use></svg>

<style>
svg {
  /*height: 32px;
  width: 32px;*/
  vertical-align: middle;
  margin: 0;
  padding: 0;
}
</style>
