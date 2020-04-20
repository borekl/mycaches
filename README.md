# MyCaches

Simple web app for exhibiting and managing my lists of geocaching finds
and hides. Written to replace manually maintained HTML page. Also written
to learn more about writing proper perl web backend (CGI.pm is "bit" dated)
with a view to converting my existing CGI.pm apps to something more modern.

The **backend** part is written in perl and uses SQLite as database and
Plack as framework to handle HTTP requests and responses as well as CGI
adaptation layer.

The **frontend** is written with Vue.js.
