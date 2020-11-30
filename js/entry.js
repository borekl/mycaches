document.addEventListener("DOMContentLoaded", () => {

  /* custom rating inputs */

  document.querySelectorAll('.input-rating').forEach(el => {
    let ctrl = el.querySelectorAll('.fivestar')[0];
    let mask = ctrl.querySelectorAll('.mask')[0];
    let rect = ctrl.getBoundingClientRect();
    let input = el.querySelectorAll('input')[0];

    ctrl.addEventListener('click', evt => {
      let val = (evt.clientX - rect.x) / rect.width;
      let val2 = Math.trunc(val * 10) / 2 + 0.5;
      if(val2 == 0.5 && input.value == val2) val2 = 0;
      if(val2 < 1) val2 = 1;
      input.value = val2;
      mask.style.width = (100 - (val2 * 20)) + '%';
    })
  })

  /* emoji pseudo-buttons */

  document.querySelectorAll('.input-emoji').forEach(el => {
    let input = el.querySelectorAll('input')[0]
    let values = [...el.getAttribute('data-emojis')]

    function show(value) {
      if(value) {
        el.textContent = values[value-1]
        if(value == 1) el.classList.remove('input-emoji-dimmed')
      } else {
        el.textContent = values[0]
        el.classList.add('input-emoji-dimmed')
      }
    };

    show(parseInt(input.value));

    el.addEventListener('click', evt => {
      let value = parseInt(input.value) + 1;
      if(value > values.length) value = 0;
      input.value = value;
      show(value);
    })
  })

})
