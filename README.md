# MyCaches

Simple web app for keeping track of my geocaching finds and hides. Created to
replace a manually maintained HTML page.  Written in perl and uses
SQLite as database, Web::Simple as web framework and Template::Toolkit as
templating engine.

## Development

Run in development mode with
[plackup](https://metacpan.org/pod/distribution/Plack/script/plackup)
using following command-line. This uses Plack middleware to serve static
components.

    mycaches.pl -r -e 'enable "Plack::Middleware::Static", path => qr/\.(css|svg)$/'

There's a prepared run.sh file that you can use in place of the above.

## Production

There are number of ways to run the app in production. Here I give example
that uses [starman](https://metacpan.org/pod/Starman) application server
with Apache httpd frontend.

Unit file example for systemd is included in the repository. It contains following definition:

    [Unit]
    Description=MyCaches
    After=syslog.target

    [Service]
    WorkingDirectory=/opt/mycaches
    User=mycaches
    Group=mycaches
    Type=forking
    ExecStart=/usr/bin/starman -l 127.0.0.1:30448 \
      --workers 2 -D --error-log=mycaches_error.log \
      -e 'enable "Plack::Middleware::Static", path => qr/\.(css|svg|js)$/' \
      mycaches.pl
    Restart=always

    [Install]
    WantedBy=multi-user.target

Copy the file into `/lib/systemd/system` and start the instance with
`systemctl start mycaches`. You can verify that its up and running:

    $ http -h http://127.0.0.1:30448/

    HTTP/1.1 200 OK
    Connection: keep-alive
    Content-Type: text/html; charset=utf-8
    Date: Mon, 07 Dec 2020 13:45:54 GMT
    Expires: Mon, 07 Dec 2020 13:55:54 GMT
    Refresh: 33245
    Transfer-Encoding: chunked

To make the application available to the outside world, we will configure
Apache httpd as reverse proxy, which will serve the app in `/gc/mycaches` path.
Note, that you apart from *mod_proxy* you also need to load *mod_proxy_html* and *mod_xml2enc* Apache modules.

    <Location "/gc/mycaches/">
      ProxyHTMLEnable On
      ProxyPass "http://127.0.0.1:30448/"
      ProxyPassReverse "http://127.0.0.1:30448/"
      ProxyHTMLLinks a href
      ProxyHTMLLinks link href
      ProxyHTMLLinks base href
      ProxyHTMLLinks form action
      ProxyHTMLLinks use "xlink:href"
      ProxyHTMLURLMap http://127.0.0.1:30488/ /gc/mycaches/
      ProxyHTMLURLMap / /gc/mycaches/
      ProxyHTMLDocType "<!doctype html>"
    </Location>

This will make everything accessible from the outside. To limit outside
access to adding and editing entries, we can add an address filter. Let's
supposed our internal network is 192.168.0.0/24.

    <Location "/gc/mycaches/">
      Require ip 192.168.0.0/24
    </Location>

    <LocationMatch "^/gc/mycaches/(|hides.*|finds.*|.*\.css|.*\.svg)$">
      Require all granted
    </LocationMatch>

This will allow the "read-only" part of the app to be accessed from anywhere.
