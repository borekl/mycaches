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
    let input = el.nextSibling;
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

    let value = input.value;
    if(!value) input.value = value = 0;
    show(parseInt(input.value));

    el.addEventListener('click', evt => {
      let value = parseInt(input.value);
      if(!value) value = 0;
      value++;
      if(value > values.length) value = 0;
      input.value = value;
      show(value);
    })
  })

  /* cache-type selection menu */

  let
    popup = document.querySelectorAll('.popup')[0],
    ctype_icon = document.querySelectorAll('.input-cachetype svg use')[0],
    ctype_input = document.querySelectorAll('.grid-icon input')[0];

  document.querySelectorAll('.cachetype').forEach(el => {
    el.addEventListener('click', evt => {
      let icon_href = el.querySelectorAll('svg use')[0].getAttribute('xlink:href');
      ctype_icon.setAttribute('xlink:href', icon_href);
      ctype_input.value = icon_href.match(/(\d+)$/)[1];
      popup.style.display = 'none';
      evt.stopPropagation();
    })
  })

  document.querySelectorAll('.input-cachetype').forEach(el => {
    popup.addEventListener('click', (evt) => {
      if(evt.target.classList.contains('popup')) {
        popup.style.display = 'none';
      }
    });
    el.addEventListener('click', () => popup.style.display = 'flex');
  })
})
