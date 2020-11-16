# MyCaches

Simple web app for exhibiting my list of geocaching finds and hides. 
Written to replace a manually maintained HTML page.  Written in perl and uses
SQLite as database, Web::Simple as web framework and Template::Toolkit as
templating engine.

## Development

Run in development mode with plackup using following command-line. This uses
Plack middleware to serve static components.

    mycaches.pl -r -e 'enable "Plack::Middleware::Static", path => qr/\.(css|svg)$/'

## Production

Use following Apache configuration to serve the application. This rewrites
path so that the route part of the URI is appended to the CGI filename and
made available to Web::Simple in PATH_INFO.

    <Directory /some/path/mycaches/>
      RewriteEngine On
      Options ExecCGI FollowSymlinks
      DirectoryIndex disabled
      AddHandler cgi-script .cgi
      SetEnv PLACK_ENV deployment
      RewriteCond %{REQUEST_FILENAME} !-f
      RewriteRule "^(.*)$" "mycaches.cgi/$1" [L,PT]
    </Directory>

