#!/bin/bash

# Run the script while serving CSS/SVG files from the frontend

./mycaches.pl -r -e 'enable "Plack::Middleware::Static", path => qr/\.(css|svg)$/, root => "../frontend" '
