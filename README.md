![Screenshot](https://i.imgur.com/sYWJtrV.png)

# MyCaches

Simple web app for keeping track of my
[geocaching](https://www.geocaching.com/) finds and hides. Created to
replace a manually maintained HTML page. Written in perl using Mojolicious
framework with Svelte front-end components. Please note that this
is personal tool so it may be rather unpolished in some parts.

* [Setup](#setup)
    * [Configure the application](#configure-the-application)
    * [Create an admin user](#create-an-admin-user)
    * [Front-end setup](#front-end-setup)
    * [Verify setup](#verify-setup)
* [Development](#development)
* [Production](#production)

-----

## Setup

### Configure the application

Before you can run the web application for the first time, some setup is needed.
Clone the repository and cd into it. `my_caches.conf` contains the application
configuration file, which has following default:

    {
      secrets => [ 'MySecr3t!' ],
      session_exp => 86400,
    
      hypnotoad => {
        listen => [ 'http://*:30449' ],
        workers => 2,
        proxy => 1,
      },
    }

The default should be fine, but you really need to change the secret to something
else.

### Create an admin user

Only logged in users can add, modify or delete caches. Therefore, you need
to add at least one user. The app has built-in command-line tool `users`
to manage users. Passwords are stored as
[Argon2](https://en.wikipedia.org/wiki/Argon2) hashes in the database.

You can use `users -h` to see help:

    ~/dev/mycaches$ ./script/my_caches users -h
    Usage: APPLICATION users [OPTIONS]
    -l,--list         list users
    -a,--add USER     add new user
    -u,--update USER  update existing user's password
    -d,--delete USER  remove existing user
    -p,--password PW  specify password

Create a new user with the `-a` and `-p` options:

    ~/dev/mycaches$ ./script/my_caches users -a 'daniel' -p 'Pa$$w0rd'
    User daniel created

You can list of known users with the `-l` option:

    ~/dev/mycaches$ ./script/my_caches users -l
    Authorized users:
    daniel

### Front-end setup

You need to have npm and nodejs installed for this to work. Go into the
`frontend` directory and run:

    npm install
    npm run build

### Verify setup

Now you should be ready to run the app. Before you start setting the
actual production environment, verify that you can run the app in
development mode as described below.

The *morbo* server presents the app on port 3000 by default, so go there
with your browser (e.g. http://127.0.0.1:3000/). You should see two
empty tables for finds and hides. Note, that you can only add entries
from /finds and /hides URL, not from the frot page! Try logging in and
adding a cache entry to make sure everything is OK.

When the above works, proceed to the **Production** section of this README.

## Development

To run the app for development, cd into the base directory and run it with
Mojolicious's *morbo* server:

    ~/dev/mycaches$ morbo script/my_caches
    Web application available at http://127.0.0.1:3000

## Production

To run the application in production mode we'll describe a setup
with Mojolicious *hypnotoad* pre-forking server and Apache 2.4
acting as a reverse proxy.

Let's suppose you want to run the up under `/gc/mycaches` path
on your Apache web server. The configuration is as follows:

    Redirect /gc/mycaches /gc/mycaches/
    <Location "/gc/mycaches/">
      ProxyPass "http://127.0.0.1:30449/"
      ProxyPassReverse "http://127.0.0.1:30449/"
      RequestHeader set X-Forwarded-Path /gc/mycaches/
    </Location>

Restart apache and start hypnotoad to verify the above setup works.
You should be access your application under `/gc/mycaches` path
on your server.

    ~/dev/mycaches$ hypnotoad -f ./script/my_caches
    [2021-03-07 11:28:47.37353] [11042] [info] Listening at "http://*:30449"
    Web application available at http://127.0.0.1:30449
    [2021-03-07 11:28:47.37409] [11042] [info] Manager 11042 started
    [2021-03-07 11:28:47.38109] [11042] [info] Creating process id file "/opt/mycaches/script/hypnotoad.pid"
    [2021-03-07 11:28:47.38423] [11044] [info] Worker 11044 started
    [2021-03-07 11:28:47.38576] [11043] [info] Worker 11043 started

If everything works, you are almost finished. You only need to integrate
the application with your OS for it to be properly managed. On a Linux with
systemd you can use supplied unit file (you must edit it to match
your setup):

    [Unit]
    Description=MyCaches
    After=network.target
    
    [Service]
    WorkingDirectory=/opt/mycaches
    User=mycaches
    Group=mycaches
    Type=forking
    PidFile=/opt/mycaches/script/hypnotoad.pid
    ExecStart=/usr/local/bin/hypnotoad /opt/mycaches/script/my_caches
    ExecReload=/usr/local/bin/hypnotoad /opt/mycaches/script/my_caches
    KillMode=process
    
    [Install]
    WantedBy=multi-user.target

Copy the unit file to appropriate location (such as `/etc/systemd/system`)
and you can enable and start the app with *systemctl*:

    ~# systemctl enable mycaches
    Created symlink /etc/systemd/system/multi-user.target.wants/mycaches.service → /etc/systemd/system/mycaches.service.
    ~# systemctl start mycaches
