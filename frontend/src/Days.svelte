<script>
  export let d;
  let r;

  $: {
    r = '';
    if(d.years) r = `${d.years} year`;
    if(d.years > 1) r += 's';

    if(r != '') r += ' ';
    r += `${d.rdays} day`;
    if(d.rdays != 1) r += 's';
  }

</script>

{r}
