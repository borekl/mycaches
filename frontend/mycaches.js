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


document.addEventListener("DOMContentLoaded", function(event) {

  getList().then(data => {
    var vm = new Vue({
      el: '#app',
      data: {
        d: data,
      },
    });
  });

});
