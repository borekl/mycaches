// SVG icon mapping
// t-traditional, ?-mystery, m-multicache, w-wherigo,
// l-letterbox,L-lab,v-virtual,e-earth,E-event,M-mega,G-giga,C-CITO

let svgIconMap = {
  't': 'icon-2',
  'm': 'icon-3',
  '?': 'icon-8',
  'e': 'icon-137',
  'v': 'icon-4',
  'w': 'icon-1858',
};


/*--- Cache type icon component --------------------------------------------*/

Vue.component('cache-icon', {
  props: [ 'type', 'disabled' ],
  data() {
    return {
      icon: null,
    }
  },
  created() {
    if(this.type && this.type in svgIconMap) {
      this.icon = svgIconMap[this.type];
      if(this.disabled) this.icon += '-disabled';
    }
  },
  template: `<svg><use :xlink:href="'cache-types.svg#'+icon" /></use></svg>`,
});


/*--- Cache D/T rating component -------------------------------------------*/

Vue.component('cache-rating', {
  props: [ 'difficulty', 'terrain' ],
  data() {
    return {
      d1: null, d2: null,
      t1: null, t2: null,
    }
  },
  created() {
    if(this.difficulty) {
      this.d1 = '★'.repeat(Math.floor(this.difficulty / 2));
      this.d2 = '★'.repeat(this.difficulty % 2);
    }
    if(this.terrain) {
      this.t1 = '★'.repeat(Math.floor(this.terrain / 2));
      this.t2 = '★'.repeat(this.terrain % 2);
    }
  },
  template:
    `<span>
      {{d1}}<span v-if="d2" class="hlf">{{d2}}</span><br>
      {{t1}}<span v-if="t2" class="hlf">{{t2}}</span>
    </span>`,
});


/*--- Cache name component -------------------------------------------------*/

Vue.component('cache-name', {
  props: [ 'row' ],
  data() { return {} },
  template:
    `<div class="cachename">
      <div :class="{archived: row.archived}">
        <template v-if="row.gallery">
          <a :href="'/fotky/gc/' + row.cacheid + '/'">{{row.name}}</a>
        </template>
        <template v-else>
          {{row.name}}
        </template>
        <span class="emoji" v-if="row.gallery">&#x1f4f7;</span>
      </div>
      <div class="emoji" v-if="row.favorite || row.xtf">
        <template v-if="row.favorite">&#x1f499;</template>
        <template v-if="row.xtf == 1">&#x1f947;</template>
        <template v-if="row.xtf == 2">&#x1f948;</template>
        <template v-if="row.xtf == 3">&#x1f949;</template>
      </div>
    </div>`,
});


/*--- MAIN -----------------------------------------------------------------*/

function getList(req)
{
  let req_options = {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  };

  if(req) req_options.body = JSON.strigify(req);

  return fetch('mycaches.cgi', req_options)
  .then(response => {
    if(!response.ok) {
      throw new Error(`Failed to retrieve data (${response.statusText})`);
    }
    return response.json();
  });
}


document.addEventListener("DOMContentLoaded", async function() {

  var vm = new Vue({

    el: '#app',
    data: {
      d: null,
    },

    async created() {
      this.d = await getList();
    },

    methods: {

      age(row) {
        if(row.prev) {
          let m = moment(row.found);
          return m.diff(moment(row.prev), 'days');
        } else {
          return null;
        }
      },

      held(row) {
        // not for lab caches
        if(row.ctype == 'L') return null;
        // otherwise...
        let m;
        if(row.next)
          m = moment(row.next);
        else
          m = moment();

        return m.diff(moment(row.found), 'days');
      },

      age_hide(row) {
        let m;
        if(row.found) {
          m = moment(row.found);
        } else if(row.published) {
          m = moment(row.published);
        } else {
          return null;
        }
        return moment().diff(m, 'days');
      },

      hideStatus(row) {
        let s;

        switch(row.status) {
          case 10: s = 'in development'; break;
          case 11: s = 'waiting to be placed'; break;
          case 12: s = 'waiting for publication'; break;
        }

        return s;
      }
    }

  });

});
