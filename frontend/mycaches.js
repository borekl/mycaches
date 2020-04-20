function getList()
{
  return fetch('mycaches.cgi')
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
    }
  });

});
