<script>
  export let value;
  $: mask_width = (100 - (value * 20));
  let ratebox;

  function rate(e) {
    let rect = ratebox.getBoundingClientRect();
    let val = (e.clientX - rect.x) / rect.width;
    let val2 = Math.trunc(val * 10) / 2 + 0.5;
    if(val2 < 1) val2 = 1;
    value = val2;
  }
</script>

<span
  bind:this={ratebox}
  class="fivestar"
  on:click={rate}
>★★★★★<span
  class="mask"
  style="width:{mask_width+'%'}"
></span></span>

<style>
.fivestar {
  position: relative;
  cursor: pointer;
  user-select: none;
}
.mask {
  display: inline-block;
  position: absolute;
  top: 0;
  right: 0;
  height: 100%;
  width: 0%;
  background-color: rgba(255,255,255,0.8);
}
</style>
