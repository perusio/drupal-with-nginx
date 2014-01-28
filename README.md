# Nginx configuration for running Drupal

## Introduction

   This is an example configuration from running Drupal using
   [nginx](http://nginx.org). Which is a high-performance non-blocking
   HTTP server.

   Nginx doesn't use a module like Apache does for PHP support. The
   Apache module approach simplifies a lot of things because what you
   have in reality is nothing less than a PHP engine running on top of
   the HTTP server. 

   Instead nginx uses [FastCGI](http://en.wikipedia.org/wiki/FastCGI)
   to proxy all requests for PHP processing to a php fastcgi daemon that
   is waiting for incoming requests and then handles the php file
   being requested.

   Although the fcgi approach is more cumbersome to set up it provides
   a greater degree of control over which actions are permitted, hence
   greater security.

   This configuration started life as a fork of
   [yhager's](github.com/yhager/nginx_drupal) configuration, tempered
   by [omega8cc](http://github.com/omega8cc/nginx-for-drupal) and
   [Brian Mercer](http://test.brianmercer.com/content/nginx-configuration-drupal)
   (dead link) configurations. 
   
   I've since then changed it substantially. Tried to remove as best
   as I can the traces of bad habits promoted by Apache's
   configuration logic. Namely the use of a `.htaccess` and what it
   entails in terms or _reverse logic_ on the server
   configuration. I've incorporated tidbits and advices gotten,
   mostly, from the nginx mailing list and the
   [nginx Wiki](http://wiki.nginx.org).

## I'm in a hurry just show me how to install it

Jump **immediately** to the [installation](#installation).
I'll read up on all other stuff **later**.  

## Layout
   
The configuration comes in **two** flavors:
   
 1. Drupal 6.

 2. Drupal 7.
    
Furthermore there are **two** options for each configuration:
      
   1. A **non drush aware** option that uses `wget/curl` to run cron
      and updating the site using `update.php`, i.e., via a web
      interface. 

   2. A **drush aware flavor** that runs cron and updates the site
      using [drush](http://drupal.org/project/drush).

      To get drush to run cron jobs the easiest way is to define your
      own [site aliases](http://drupal.org/node/670460). See the
      example aliases file `example.aliases.drushrc.php` that comes
      under the `examples` directory in the drush distribution.

      Example: You create the aliases for example.com and example.net,
      with aliases `@excom` and `@exnet` respectively.

      Your crontab should contain something like:

          COLUMNS=80
          DRUSH=/full/path/to/drush
          */50 * * * * $DRUSH @excom cron -q
          1 2 * * * $DRUSH @exnet cron -q

      This means that the cron job for example.com will be run every
      50 minutes and the cron job for example.net will be run every
      day at 02:01 hours. Check the section 7 of the Drupal
      `INSTALL.txt` for further details about running cron.

      Note that the `/path/to/drush` is the path to the **shell script
      wrapper** that comes with drush not to to the `drush.php`
      script. If using `drush.php` then add `php` in front of the
      `/path/to/drush.php`.

## Branching

The configuration has 3 main branches:

 1. A [D7](https://github.com/perusio/drupal-with-nginx/tree/D7) branch
    if you're running **Drupal 7** sites only on a given machine **use
    this branch**.
    
 2. A [D6](https://github.com/perusio/drupal-with-nginx/tree/D6) branch
    if you're running **Drupal 6** sites only on a given machine **use
    this branch**.   
    
 3. A [master](https://github.com/perusio/drupal-with-nginx) branch if
    you're running **both Drupal 6 and Drupal 7** sites on a given
    machine **use this branch**.

## Escaped URIs

It happens that some sites have URIs that use
[reserved characters](https://en.wikipedia.org/wiki/Percent-encoding#Percent-encoding_reserved_characters). In
that case because we're not using **any rewrite** and since Nginx
makes the exact matching of locations without escaping the reserved
characters present in a URI we must use another mechanism for
performing the escape. I've opted for the
[`set_by_lua`](http://wiki.nginx.org/HttpLuaModule#set_by_lua)
directive made available by the
[Embedded Lua](http://wiki.nginx.org/HttpLuaModule) module. This
module provides a method
[`ngx.escape_uri`](http://wiki.nginx.org/HttpLuaModule#ngx.escape_uri)
that encodes a URI.

    ## Drupal 7 site. We define a new variable that has the escaped
    ## URI as value.
    set_by_lua $escaped_uri 'return ngx.escape_uri($uri)';

This means that each configuration has an **escaped uri**
version.

## Configuration Selection Algorithm

 1. I'm **not** using [Boost](http://drupal.org/project/boost):   
  * On **drupal 7** use the `drupal.conf` config in your vhost
    (`server` block): `include apps/drupals/drupal.conf;`.
  * On **drupal 7** having to serve URIs that need to be **escaped**,
    e.g., that have `+` and/or `?` then use the `drupal_escaped.conf`
    config in your vhost (`server` block): 
    `include apps/drupal/drupal_escaped.conf`.
  * On **drupal 6** use the `drupal6.conf` config in your vhost
    (`server` block): `include apps/drupals/drupal6.conf;`.
  * On **drupal 6** if having to serve URIs that need to be
    **escaped**, e.g., that have `+` and/or `?` then use the
    `drupal6_escaped.conf` config in your vhost (`server` block):
    `include apps/drupal/drupal6_escaped.conf`.
 2. I'm using [Boost](http://drupal.org/project/boost) for caching
      on my drupal site.
  * On **drupal 7** use the `drupal_boost.conf` config in your vhost
    (`server` block): `include apps/drupal/drupal_boost.conf;`.
  * On **drupal 7** if having to serve URIs that need to be
    **escaped**, e.g., that have `+` and/or `?` then use the
    `drupal_boost_escaped.conf` config in your vhost (`server` block):
    `include apps/drupal/drupal_boost_escaped.conf`.
  * On **drupal 6** use the `drupal_boost6.conf` config in your vhost
    (`server` block): `include apps/drupal/drupal_boost6.conf;`.
  * On **drupal 6** if having to serve URIs that need to be
    **escaped**, e.g., that have `+` and/or `?` then use the
    `drupal_boost6_escaped.conf` config in your vhost (`server`
    block): `include apps/drupal/drupal_boost6_escaped.conf`.
 3. I'm **not using drush** for updating and running
    cron. Additionally you should also include the
    `drupal_cron_update.conf` config in your vhost (`server` block):
    `include apps/drupal/drupal_cron_update.conf;`
 4. I'm using **drupal 8**. Just use the drupal 7 configuration. The
    only thing that changes so far is the location of `install.php`.
    
    It's `/core/install.php` instead of `install.php`.
    
## Boost and Drupal 6

The standard Drupal 6 core sets cookies also for anonymous
users. Therefore the following map directive from `map_cache.conf`
will result in the Boost generated pages **not being served**.

    map $http_cookie $no_cache {
        default 0;
        ~SESS 1; # PHP session cookie
    }

If you're using the standard Drupal 6 **without**
[`no_anon`](http://drupal.org/project/no_anon) then the cache bursting
map directive is:

    map $http_cookie $no_cache {
        default 0;
        ~DRUPAL_UID 1; # PHP session cookie
    }

This is properly documented in `map_cache.conf`.

## Drupal 6 Global Redirect and the 0 Rewrites Configuration

There's a setting that is enabled by default in
[`globalredirect`](http://drupal.org/project/globalredirect) that
removes the trailing slash in the URIs. That setting creates a
redirect loop with the **0 rewrites config** provided by
`sites-available/drupal.conf` or `sites-available/drupal_boost.conf`
if using [Boost](http://drupal.org/project/boost).

There are two ways to deal with that:

 1. Install the module
    [`nginx_fast_config`](http://drupal.org/project/nginx_fast_config)
    that takes care of this setting removing it from the settings form
    at `/admin/settings/globalredirect` and presents a status line on
    the status page at `/admin/reports/status`. This module fixes the
    issues for you.
    
 2. Take care of the **deslash** setting yourself by disabling it at
    `/admin/settings/globalredirect`. Note that this is enabled by
    **default**. 
    
This is strictly a **drupal 6** issue.

## General Features

   1. The use of two `server` directives to do the domain name
   rewriting, usually redirecting `www.example.com` to `example.com`
   or vice-versa. As recommended in
   [nginx Wiki Pitfalls](http://wiki.nginx.org/Pitfalls#Server_Name)
   page.

   2. **Clean URL** support.

   3. Access control for `cron.php`. It can only be requested from a
   set of IPs addresses you specify. This is for the **non drush
   aware** version.

   4. Support for [multisite](http://drupal.org/documentation/install/multi-site).

   5. Support for the [Boost](http://drupal.org/project/boost) module.

   6. Support for virtual hosts. The `example.com.conf` file.

   7. Support for [Sitemaps](http://drupal.org/project/site_map) RSS feeds.

   8. Support for the
      [Filefield Nginx Progress](http://drupal.org/project/filefield_nginx_progress)
      module for the upload progress bar.

   9. Use of **non-capturing** regex for all directives that are not
      rewrites that need to use URI components.1

   10. IPv6 and IPv4 support.
   
   11. Support for **private file** serving in drupal.

   12. Support for
       [hot link protection](https://simple.wikipedia.org/wiki/Hot-linking)
       imagecache generated images.

   13. If using `php-cgi` with UNIX sockets in `/tmp/` subdirectory
       with permissions **700**, i.e., accessible only to the user
       running the process.  You may consider the
       [init script](github.com/perusio/php-fastcgi-debian-script)
       that I make available here on github that launches the PHP
       FastCGI daemon and spawns new instances as required. This is
       not needed if you're using php-fpm.
  
   14. End of the [expensive 404s](http://drupal.org/node/76824
       "Expensive 404s issue") that Drupal usually handles when
       using Apache with the default `.htaccess`.
  
   15. Possibility of using **Apache** as a backend for dealing with
       PHP. Meaning using Nginx as
       [reverse proxy](http://wiki.nginx.org/HttpProxyModule "Nginx
       Proxy Module").
       
   16. [Advanced Help](http://drupal.org/project/advanced_help)
       support.
       
   17. [Advanced Aggregation](http://drupal.org/project/advagg)
       support.
       
   18. [Microcaching](http://fennb.com/microcaching-speed-your-app-up-250x-with-no-n)
       support for both **anonymous** and **authenticated** users.
       
   19. Support for escaped URIs, i.e., URIs that require percent
       encoding.
       
   20. [ETag](https://en.wikipedia.org/wiki/HTTP_ETag) support. This
       requires a Nginx version greater or equal to **1.3.3**.
       
   21. Support for drupal 8.
   
   22. Support for the [`file_force`](http:/drupal.org/project/file_force) module.
           
## Secure HTTP aka SSL/TLS support

   1. By default and since version
      [0.8.21](http://nginx.org/en/docs/http/configuring_https_servers.html
      "Nginx SSL/TLS protocol supported defaults") only SSLv3 and
      TLSv1 are supported. The anonymous Diffie-Hellman (ADH) key
      exchange and MD5 message autentication algorithms are not
      supported. They can be enabled explicitly but due to their
      **insecure** nature they're discouraged. The same goes for
      SSLv2.
      
   2. SSL/TLS shared cache for SSL session resume support of 10
      MB. SSL session timeout is set to 10 minutes.
      
   3. Note that for session resumption to work the setting of the SSL
      socket as default, at least, is required. Meaning a listen
      directive like this:
      
      `listen [::]:443 ssl default_server;`
      
      This is so because session resumption takes place before any TLS
      extension is enabled, namely
      [Server Name Indication](http://en.wikipedia.org/wiki/Server_Name_Indication
      "SNI"). The ClientHello message requests a session ID from a
      given IP address (server). Therefore the default server setting
      is **required**.
       
      Another option, the one I've chosen here, is to move the
      `ssl_session_cache` directive to the `http` context setting. Of
      course the downside of this approach is that the
      `ssl_session_cache` settings are the same for **all** configured
      virtual hosts.
      
## Security Features

   1. No direct access to PHP scripts. All PHP scripts, including
      `index.php` are acessed only internally.

   2. The use of a `default` configuration file to block all illegal
      `Host` HTTP header requests.

   3. Access control using
      [HTTP Basic Auth](http://wiki.nginx.org/NginxHttpAuthBasicModule)
      for `install.php` and other Drupal sensitive files. The
      configuration expects a password file named `.htpasswd-users` in
      the top nginx configuration directory, usually `/etc/nginx`. I
      provide an empty file. This is also for the **non drush aware**
      version.

      If you're on Debian or any of its derivatives like Ubuntu you
      need either the
      [thttpd-util](http://packages.debian.org/search?keywords=thttpd-util)
      or [apache2-utils](http://packages.debian.org/search?suite%3Dall&section%3Dall&arch%3Dany&searchon%3Dnames&keywords%3Dapache2-utils)
   package installed. 
   
      With `thttpd-util` create your password file by issuing:
   
         thtpasswd -c .htpasswd-users <user> <password>
   
      With `apache2-utils` create your password file by issuing:

         htpasswd -d -b -c .htpasswd-users <user> <password>

      You should delete this command from your shell history
      afterwards with `history -d <command number>` or alternatively
      omit the `-b` switch, then you'll be prompted for the password.

      This creates the file (there's a `-c` switch). For adding
      additional users omit the `-c`.

      If you're on Debian or any of its derivatives like Ubuntu you
      need the
      [apache2-utils](http://packages.debian.org/search?suite%3Dall&section%3Dall&arch%3Dany&searchon%3Dnames&keywords%3Dapache2-utils)
      package installed. Then create your password file by issuing:

          htpasswd -d -b -c .htpasswd-users <user> <password>

      You should delete this command from your shell history
      afterwards with `history -d <command number>` or alternatively
      omit the `-b` switch, then you'll be prompted for the password.

      This creates the file (there's a `-c` switch). For adding
      additional users omit the `-c`.

      Of course you can rename the password file to whatever you want,
      then accordingly change its name in drupal_boost.conf.

   4. Support for
      [`X-Frame-Options`](https://developer.mozilla.org/en/The_X-FRAME-OPTIONS_response_header)
      HTTP header to avoid Clickjacking attacks.
      
   5. Support for
      [`X-Content-Options`](http://blogs.msdn.com/b/ie/archive/2008/09/02/ie8-security-part-vi-beta-2-update.aspx?Redirected=true)
      for avoiding MIME type deviation from the declared
      `Content-Type`.

   6. Protection of the upload directory. You can try to bypass the
      UNIX `file` utility or the PHP `Fileinfo` extension and upload a
      fake jpeg:
   
          echo -e "\xff\xd8\xff\xe0\n<?php echo 'hello'; ?>" > test.jpg
      
      If you run `php test.jpg` you get 'hello'. The fact is that
      **all files** with php extension are either matched by a
      particular location, as is the case for `xmlrpc.php`,
      `update.php` and `install.php` or match the last directive of
      the configuration:

          location ~* ^.+\.php$ {
            return 404; 
          }

      Returning a 404 (Not Found) for every PHP file not matched by
      all the previous locations.
      
      Note that `index.php` is accessed only **indirectly**, meaning
      it always from within the Nginx config. You cannot access it
      directly from outside.

   7. Use of [Strict Transport Security](http://www.chromium.org/sts
      "STS at chromium.org") for enhanced security. It forces during
      the specified period for the configured domain to be contacted
      only over HTTPS. Requires a modern browser to be of use, i.e.,
      **Chrome/Chromium**, **Firefox 4** or **Firefox with
      NoScript**.
      
   8. DoS prevention with a _low_ number of connections by client
      allowed: **32**. This number can be adjusted as you see fit.
   
   9. The Drupal specific headers like `X-Drupal-Cache` provided by
      [pressflow](https://github.com/pressflow/6) or the `X-Generator`
      header that Drupal 7 sets are both **hidden**. 

   10. Limitation of allowed HTTP methods. Out of the box only `GET`,
      `HEAD` and `POST`are allowed.
      
   11. Protection of the `/admin` URIs with Basic Auth.   
      
## Private file handling

   This config assumes that **private** files are stored under a directory
   named `private`. I suggest `sites/default/files/private` or
   `sites/<sitename>/files/private` but can be anywhere inside the site
   root as long as you keep the top level directory name `private`. If
   you want to have a different name for the top level then replace in
   the location `~* private` in `drupal.conf` and/or `drupal7.conf`
   the name of your private files top directory.

   Example: Calling the top level private files directory `protected`
   instead of `private`.
       
       location ^~ /sites/default/files/protected {
         internal;
       }
  
   Now any attempt to access the files under this directory directly
   will return a 404.

   Note that this practice it's not what's usually
   [recommended](http://drupal.org/node/344806 "Drupal handbook page
   on private files"). The _usual_ practice involves setting up a
   directory outside of files directory and giving write permissions to
   the web server user. While that might be a simple alternative in
   the sense that doesn't require to tweak the web server
   configuration, I think it to be less advisable, in the sense that
   now there's **another** directory that is writable by the server. 
   
   I prefer to use a directory under `files`, which is the only one
   that is writable by the web server, and use the above location
   (`protected` or `private`) to block access by the client to it.
   
   Also bear in mind that the above configuration stanza is for a
   drupal 7 or a drupal 6 site not relying on
   [purl](http://drupal.org/project/purl). For sites that use it,
   e.g., sites/products based on
   [spaces](http://drupal.org/project/spaces) like
   [OpenAtrium](http://openatrium.com) or
   [ManagingNews](http://managingnews.com) require a **regex** based
   location, i.e.:
   
       location ~* /sites/default/files/protected {
         internal;
       }
   
   in order to work properly.
   
## Fast Private File Transfer

   Nginx implements
   [Lighty X-Sendfile](http://blog.lighttpd.net/articles/2006/07/02/x-sendfile
   "Lighty's life blog post on X-Sendfile") using the header:
   [X-Accel-Redirect](http://wiki.nginx.org/XSendfile "Nginx
   implementation of X-Sendfile").
   
   This allows **fast** private file transfers. I've developed a
   module tailored for Nginx:
   [nginx\_accel\_redirect](http://drupal.org/project/nginx_accel_redirect "Module for Drupal providing fast private file transfer"). 

## Connections per client and DoS Mitigation

   The **connection zone** defined, called `arbeit` allows for **32**
   connections to be established for each client. That seems to me to
   be a _reasonable_ number. It could happen that you have a setup
   with lots of CDNs (see this
   [issue](https://github.com/perusio/drupal-with-nginx/issues#issue/2))
   or extensive
   [domain sharding](http://www.stevesouders.com/blog/2009/05/12/sharding-dominant-domains/)
   and the number of allowed connections by client can be greater than
   32, specially when using Nginx as a reverse proxy. 
   
   It may happen that 32 is not enough and you start getting a lot of
   `503 Service Unavailable` status codes as a reply from the
   server. In that case tweak the value of `limit_conn` until you have
   a working setup. This number must be as small as possible as a way
   to mitigate the potential for DoS attacks.

## ETag support

   [ETags](https://en.wikipedia.org/wiki/HTTP_ETag) are an additional
   facility to help caching of static assets on the web. Usually based
   on the file **modification time** a hash is generated. The hash is
   sent as an additional header to the client. Here's an example of a
   request reply with an ETag:
   
       HTTP/1.1 200 OK
       Server: nginx
       Date: Mon, 17 Sep 2012 17:46:36 GMT
       Content-Type: image/png
       Content-Length: 5399
       Last-Modified: Wed, 02 May 2012 16:36:16 GMT
       Connection: keep-alive
       Keep-Alive: timeout=10
       ETag: "4fa16280-1517"
       Expires: Thu, 01 Jan 1970 00:00:01 GMT
       Cache-Control: no-cache
       Accept-Ranges: bytes

## Image hotlinking protection

   Imagecache generated images can be **expensive** to generate. In
   those cases providing protection against
   [hotlinking](https://simple.wikipedia.org/wiki/Hot-linking) is a
   must.
   
   To make use of that uncomment the proper line on the `/imagecache/`
   location that includes the
   `sites-available/hotlinking_protection.conf` file.
   
   The protection is based on the
   [Nginx referer module](http://nginx.org/en/docs/http/ngx_http_referer_module.html). You
   must specify the hosts that are allowed to access the images. The
   hostnames can use wildcards or use regexes.

## HTTP allowed methods made to measure

   For a standard drupal install there's no need for any method
   besides `GET`, `HEAD` and `POST`. The allowed methods are
   enumerated in the file `map_block_http_methods.conf`.
   
   If your site uses/provide web services then you must add the
   methods you need to the list. For example if you want to allow
   `PUT` then do:
   
       map $request_method $not_allowed_method {
           default 1;
           GET 0;
           HEAD 0;
           POST 0;
           PUT 0;
       }

   Note that this enables `PUT` for all locations and clients. If you
   need a finer control then use the
   [`limit_except`](http://nginx.org/en/docs/http/ngx_http_core_module.html#limit_except)
   directive and enumerate the client IPs that are allowed to use the
   *extra* methods like `PUT`.

## Protection of the `/admin` URIs using Basic Auth

   Just uncomment the line that includes the
   `apps/drupal/admin_basic_auth.conf` file. Now whenever you got to a
   `/admin` URI the server will prompt you for a username/password
   pair. Note that by default this config provides no
   username/password values for the `.htpasswd-users` file. This is to
   avoid the creeping of laziness and that 80% of the sites that have
   the `/admin` URIs protected have the same username/password.
   
   Note that this is much more effective if at least all your logged
   in traffic goes over SSL (HTTPS).

## Multisite support

   [Drupal multisite](http://drupal.org/documentation/install/multi-site)
   is supported out of the box with this configuration you just need
   to configure the
   [`server_name`](http://nginx.org/en/docs/http/ngx_http_core_module.html#server_name)
   directive with **all** the sites that your Drupal installation
   serves.
   
   For example your Drupal installation serves the sites
   `foo.example.com`, `bar.example.net` and
   `baz.foo.example.org`. Then you need to configure your vhost like
   this:
   
       server_name foo.example.com bar.example.net baz.foo.example.org;
       
   Note that Nginx allows for the server name to be either a regex or
   a wildcard expression. See
   [this](http://nginx.org/en/docs/http/server_names.html) to delve
   deeper into the multiple ways to define server names.

   This is the most **simple** multisite setup. You can have different
   vhosts. I find that it sorts of defeats the purpose to have to deal
   with different vhosts for a multisite. You get all the advantages
   of a set of separate sites in terms of web server configuration,
   while getting no advantage in terms of code separation.

   As very wise man once said: everyhting in life is a matter of
   taste. I don't like multisite. It's something that might be handy
   for dealing with small sites, but quickly becomes unmaintanable
   with large sites. Code separation is a good thing. You've been
   warned.

## Nginx as a Reverse Proxy: Proxying to Apache for PHP

   If you **absolutely need** to use the rather _bad habit_ of
   deploying web apps relying on `.htaccess`, or you just want to use
   Nginx as a reverse proxy. The config allows you to do so. Note that
   this provides some benefits over using only Apache, since Nginx is
   much faster than Apache. Not only due to its architecture but also
   to using
   [buffering](http://wiki.nginx.org/HttpProxyModule#proxy_buffering)
   for handling upstream replies. Furthermore you can use the proxy
   cache and/or use Nginx as a load balancer.

## Static index.html file

   The `/` location is a **_fallback_** location, meaning that after
   trying all other, more specific locations, Nginx, will return here.
   
   Since there's a `try_files $uri` directive within `@cache`, if using
   [Boost](http://drupal.org/project/boost), or `@drupal`, or
   `index.php?q=$uri&$args` otherwise, as fallback it will return a
   404 if no file is found. Even if you have an `index.html` file at
   the root. That is for a request URI of `/`. It will work however
   with `/index.html`, since that's the argument of the `try_files`
   directive.
   
   There's several possible ways to fix that. Be with nested locations
   inside `location /` or with an aditional `try_files $uri/index.html`.
   
   The one I opted for is instead making use of the
   [`error_page`](http://wiki.nginx.org/HttpCoreModule#error_page)
   directive. There's an exact location `/` that issues a
   200 code and serves `/index.html` when a 404 is returned.

## Gzipped static files

 Nginx has a directive
 [`gzip_static`](http://nginx.org/en/docs/http/ngx_http_gzip_static_module.html#gzip_static)
 that when set to `on` in a given location makes it always search for
 a file ending in `.gz` before trying to serve the file. This involves
 making an **additional** `stat()` call. It isn't generally used. So
 you can save that additional call for extracting even more speed from
 Nginx.

 Example if we're trying to serve `foobar.html` in a certain location
 if `gzip_static` is set to `on`, then Nginx will make a `stat()` call
 to try to serve `foobar.html.gz` first. 

 Exceptions to that rule are rare in the drupal world. The most common
 occasion to found such a practice is when using Boost. Since there's
 a configuration option to make it create gzipped HTML pages in its
 cache.

 By default on the Boost cache locations we have:
 
     gzip_static on;

 If you have **other** locations, besides the Boost cache, that
 have gzipped files to be served you have to set:
 
     gzip_static on;
 
 Note that in order to use `gzip_static` the
 [`ngx_http_gzip_static_module`](http://nginx.org/en/docs/http/ngx_http_gzip_static_module.html)
 must be **enabled**. Check your nginx with `nginx -V` to see if the
 module is enabled.
 
## Microcaching

### Introduction

  [Microcaching](http://fennb.com/microcaching-speed-your-app-up-250x-with-no-n)
  is a caching concept that takes *simple is better* approach. Meaning
  we don't care about content expiration because the cache valid time
  is small enough for that not to be an issue. In this config we set
  it to **15** seconds. You can tune all cache parameters to your
  liking. Check the `microcache_fcgi.conf` or `microcache_proxy.conf`
  for **anonymous** users cache and `microcache_fcgi_auth.conf` or
  `microcache_proxy_auth.conf` for **authenticated** users cache.

## Microcaching and Drupal

 You can implement a **microcaching** strategy on drupal using
 [cache_warmer](http://drupal.org/project/cache_warmer). Tune the many
 options of that [drush](http://www.drush.org) command to fit your
 site traffic pattern.

### Anonymous and Authenticated users microcaching

  This configuration supports both **anonymous** and **authenticated**
  users caching. You should enable **one and only one**. The
  authenticated user cache **also** supports anonymous users.
  
  By default on both drupal 6 and drupal 7 the **anonymous** user
  microcache is enabled. If you want to use the **authenticated** user
  microcache instead comment out the line:
  
  1. `include apps/drupal/microcache_fcgi.conf` if using the FCGI
     microcache (when proxying to FCGI).
     
  2. `include apps/drupal/microcache_proxy.conf` if using the
     proxy cache (proxying to Apache or other PHP handler).
 
  and uncomment:
  
  1. `include apps/drupal/microcache_fcgi_auth.conf` if using the FCGI
     microcache (when proxying to FCGI).
     
  2. `include apps/drupal/microcache_proxy_auth.conf` if using the
     proxy cache (proxying to Apache or other PHP handler).
 
  You're set to go.
  
### Boost and authenticated user microcaching

 When using [Boost](http://drupal.org/project/boost) **you can use** the
 authenticated user microcache. It will give you an additional layer
 of caching.
 
 This is enabled by default. Comment out the `include
 sites-available/microcache_fcgi_auth.conf` or `include
 sites-available/microcache_proxy_auth.conf` line if you don't want to
 use microcaching at all with Boost.
 
### Microcaching for authenticated users under the hood

 The way microcaching for authentitcated is implemented uses a
 `$cache_uid` variable that is set on
 [`map_cache.conf`](https://github.com/perusio/drupal-with-nginx/blob/master/map_cache.conf#L21).
 
 + anonymous users get a `$cache_uid` value of `nil`.
 
 + authenticated users get a `$cache_uid` value that is the **session
   id**. Note that the named capture that grabs the session ID assumes
   that you're using the **default** setting in terms of what drupal
   calls the session cookie. Hence it starts with `SESS`. If this
   isn't the case just remove the string `SESS` from the regex.

   See
   [`drupal_settings_initialize()`](http://api.drupal.org/api/drupal/includes--bootstrap.inc/function/drupal_settings_initialize/7)
   for **drupal 7** or [`conf_init()`](http://api.drupal.org/api/drupal/includes--bootstrap.inc/function/conf_init/6) for **drupal 6** for further information.

### Useful scripts for working with Nginx cache

 Here's two useful scripts for working with the Nginx cache:
 
 1. [nginx cache inspector](https://github.com/perusio/nginx-cache-inspector)
    allows you to inspect the cache files.
    
 2. [nginx cache purge](https://github.com/perusio/nginx-cache-purge)
    allows you to purge and item or set of items from the Nginx cache.   

## IPv6 and IPv4

The configuration of the example vhosts uses **separate** sockets for
IPv6 and IPv4. This way is simpler for those not (yet) having IPv6
support to disable it by commenting out the
[`listen`](http://nginx.org/en/docs/http/ngx_http_core_module.html#listen)
directive with the `ipv6only=on` parameter.

Note that the IPv6 address uses an IP _stolen_ from the
[IPv6 Wikipedia page](https://en.wikipedia.org/wiki/IPv6). You **must
replace** the indicated address by **your** address.

For Nginx versions greater or equal than 1.3.4 IPv6 and IPv4 sockets
are **separate** by default.

Note also that socket options like `ipv6only=on` can only be specified
**once**. Hence the use of different IPv6 addresses for the server
block that redirects from `www` to the base domain in both HTTP and
HTTPS servers. 

## Installation

 1. Move the old `/etc/nginx` directory to `/etc/nginx.old`.
   
 2. Clone the git repository from github:
  
        git clone https://github.com/perusio/drupal-with-nginx.git /etc/nginx
  
    If you want to use only the Drupal specific version configuration
    you must do one of the checkouts below: 
     
  * For the **D7** branch (running **only** D7 sites on the same server):
     
            git checkout D7
        
  * For the **D6** branch (running **only** D6 sites on the same server):
     
            git checkout D6      
   
 3. Edit the `sites-available/example.com.conf` configuration file to
    suit your requirements. Namely replacing example.com with **your**
    domain.
   
 4. Setup the PHP handling method. It can be:
   
  + Upstream HTTP server like Apache with mod_php. To use this method
    comment out the `include upstream_phpcgi.conf;` line in
    `nginx.conf` and uncomment the lines:
        
         include reverse_proxy.conf;
         include upstream_phpapache.conf;

    Now you must set the proper address and port for your backend(s)
    in the `upstream_phpapache.conf`. By default it assumes the
    loopback `127.0.0.1` interface on port `8080`. Adjust
    accordingly to reflect your setup.

    Comment out **all** `fastcgi_pass` directives in either
    `drupal_boost.conf` or `drupal_boost_drush.conf`, depending which
    config layout you're using. Uncomment out all the `proxy_pass`
    directives. They have a comment around them, stating these
    instructions.
      
  + FastCGI process using php-cgi. In this case an
      [init script](https://github.com/perusio/php-fastcgi-debian-script
      "Init script for php-cgi") is required. This is how the server
      is configured out of the box. It uses UNIX sockets. You can use
      TCP sockets if you prefer.
      
  + [PHP FPM](http://www.php-fpm.org "PHP FPM"), this requires you to
    configure your fpm setup, in Debian/Ubuntu this is done in the
    `/etc/php5/fpm` directory.
       
    Look [here](https://github.com/perusio/php-fpm-example-config) for
    an **example configuration** of `php-fpm`.
      
    Check that the socket is properly created and is listening. This
    can be done with `netstat`, like this for UNIX sockets:
      
          netstat --unix -l
         
    And like this for TCP sockets:   
         
          netstat -t -l
          
    or
          sudo netstat -t -l -p

    It should display the PHP CGI socket.
   
    Note that the default socket type is UNIX and the config assumes
    it to be listening on `unix:/tmp/php-cgi/php-cgi.socket`, if using
    the `php-cgi`, or in `unix:/var/run/php-fpm.sock` using `php-fpm`
    and that you should **change** to reflect your setup by editing
    `upstream_phpcgi.conf`.
   
 5. Create the `/etc/nginx/sites-enabled` directory and enable the
    virtual host using one of the methods described below. 
      
    Note that if you're using the
    [nginx_ensite](http://github.com/perusio/nginx_ensite) script
    described below it **creates** the `/etc/nginx/sites-enabled`
    directory if it doesn't exist the first time you run it for
    enabling a site.
    
 6. Reload Nginx:
   
        /etc/init.d/nginx reload
   
 7. Check that your site is working using your browser.
   
 8. Remove the `/etc/nginx.old` directory.
   
 9. Done.
   
## Enabling and Disabling Virtual Hosts

   I've created a shell script
   [nginx_ensite](http://github.com/perusio/nginx_ensite) that lives
   here on github for quick enabling and disabling of virtual hosts.
   
   If you're not using that script then you have to **manually**
   create the symlinks from `sites-enabled` to `sites-available`. Only
   the virtual hosts configured in `sites-enabled` will be available
   for Nginx to serve.


## Troubleshooting

If by any reason you have some kind of error, please get a
[debug log](http://nginx.org/en/docs/debugging_log.html) and paste it
in a [Gist](https://gist.github.com) and **open an issue** on the
github issue queue for the module.

## Acessing the php-fpm status and ping pages

   You can get the
   [status and a ping](http://forum.nginx.org/read.php?3,56426) pages
   for the running instance of `php-fpm`. There's a
   `php_fpm_status.conf` file with the configuration for both
   features.
   
   + the **status page** at `/fpm-status`;
     
   + the **ping page** at `/ping`.

   For obvious reasons these pages are acessed only from a given set
   of IP addresses. In the suggested configuration only from
   localhost and non-routable IPs of the 192.168.1.0 network.
    
   The allowed hosts are defined in a geo block in file
   `php_fpm_status_allowed_hosts.conf`. You should edit the predefined
   IP addresses to suit your setup. 
 
   To enable the status and ping pages uncomment the line in the
   `example.com.conf` virtual host configuration file.

## Getting the latest Nginx packaged for Debian or Ubuntu

   I maintain a [debian repository](http://debian.perusio.net/unstable
   "my debian repo") with the
   [latest](http://nginx.org/en/download.html "Nginx source download")
   version of Nginx. This is packaged for Debian **unstable** or
   **testing**. The instructions for using the repository are
   presented on this [page](http://debian.perusio.net/debian.html
   "Repository instructions").
 
   It may work or not on Ubuntu. Since Ubuntu seems to appreciate more
   finding semi-witty names for their releases instead of making clear
   what's the status of the software included, meaning. Is it
   **stable**? Is it **testing**? Is it **unstable**? The package may
   work with your currently installed environment or not. I don't have
   the faintest idea which release to advise. So you're on your
   own. Generally the APT machinery will sort out for you any
   dependencies issues that might exist.

## Ad and Additional modules support

   The config is quite tight in the sense that if you have something
   that is not contemplated in the **exact** match locations,
   `/index.php`, `/install.php`, etc, and you try to make it work it
   will fail. Some Drupal modules like
   [ad](http://drupal.org/project/ad "Ad module") provide a PHP
   script. This script needs to be invoked. In the case of the **ad
   module** you must add the following location block:
   
       location = /sites/all/modules/ad/serve.php {
          fastcgi_pass phpcgi;
        }
   
   Of course this assumes that you installed the ad module such that
   is usable for all sites. To make it usable when targeting a single
   site, e.g., `mysite.com`, insert instead:
       
       location = /sites/mysite.com/modules/ad/serve.php {
          fastcgi_pass phpcgi;
       }   
       
    Proceed similarly for other modules requiring the usage of PHP
    scripts like `ad`.   

## On groups.drupal.org

   There's a [nginx](http://groups.drupal.org/nginx)
   groups.drupal.org group for sharing and learning more about using
   nginx with Drupal.

## Monitoring nginx

   I use [Monit](http://mmonit.com) for supervising the nginx
   daemon. Here's my
   [configuration](http://github.com/perusio/monit-miscellaneous) for
   nginx.

## Caveat emptor

   You should **always** test the configuration with `nginx -t` to see
   if everything is correct. Only after a successful should you reload
   nginx. On Debian and any of its derivatives you can also test the
   configuration by invoking the init script as: `/etc/init.d/nginx
   testconfig`.

## My other nginx configs on github

   + [WordPress](https://github.com/perusio/wordpress-nginx "WordPress Nginx
     config")

   + [Chive](https://github.com/perusio/chive-nginx "Chive Nginx
     config")
     
   + [Piwik](https://github.com/perusio/piwik-nginx "Piwik Nginx
     config")

   + [Redmine](https://github.com/perusio/redmine-nginx "Redmine Nginx
     configuration")

   + [SquirrelMail](https://github.com/perusio/squirrelmail-nginx
     "SquirrelMail Nginx configuration")
  
## Securing your PHP configuration

   I have created a small shell script that parses your `php.ini` and
   sets a sane environment, be it for **development** or
   **production** settings. 
   
   Grab it [here](https://github.com/perusio/php-ini-cleanup "PHP
   cleanup script").

## TODO

   + Improve the documentation. It's too vague and needs to be more
     elaborate.
          
   + Add [AgrCache](http://drupal.org/project/agrcache) support. (D7)

## Acknowledgments

   The great bunch at the [Nginx](http://groups.drupal.org/nginx
   "Nginx Drupal group") group on groups.drupal.org. They've helped me
   sort out the snafus on this config and offered insights on how to
   improve it.

   Thanks to [Richard](https://github.com/perusio/drupal-with-nginx/issues/34) for setting
   me down the path of image hotlinking protection.
