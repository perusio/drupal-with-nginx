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
   proxy all requests for PHP processing to a php fastcgi daemon that
   is waiting for incoming requests and then handles the php file
   being requested.

   Although the fcgi approach is more cumbersome to set up it provides
   a greater degree of control over which actions are permitted, hence
   greater security.

   This configuration uses a lot of stuff stolen from both
   [yhager](github.com/yhager/nginx_drupal),
   [omega8cc](http://github.com/omega8cc/nginx-for-drupal) and
   [Brian Mercer](http://test.brianmercer.com/content/nginx-configuration-drupal)
   configurations. I've incorporated some tidbits of advice I've
   gotten from both the nginx mailing list and the
   [nginx Wiki](http://wiki.nginx.org).

## Layout
   
   The configuration has **two** possible choices.

   1. A **non drush aware** version that uses `wget/curl` to run cron
      and updating the site using `update.php`, i.e., via a web
      interface.

   2. A **drush aware version** that runs cron and updates the
      site using [drush](http://drupal.org/project/drush).

      To get drush to run cron jobs the easiest way is to define your
      own [site aliases](http://drupal.org/node/670460). See the
      example aliases file `example.aliases.drushrc.php` that comes
      under the `examples` directory in the drush distribution.

      Example: You create the aliases for example.com and example.org,
      with aliases `@excom` and `@exnet` respectively.

      Your crontab should contain something like:

          COLUMNS 80
          */50 * * * * /path/to/drush @excom cron > /dev/null
          1 2 * * * /path/to/drush @exnet cron > /dev/null

      This means that the cron job for example.com will be run every
      50 minutes and the cron job for example.net will be run every
      day at 02:01 hours. Check the section 7 of the Drupal
      `INSTALL.txt` for further details about running cron.

      Note that the `/path/to/drush` is the path to the **shell script
      wrapper** that comes with drush not to to the `drush.php`
      script. If using `drush.php` then add `php` in front of the
      `/path/to/drush.php`.
    
## Drupal 7
    
   The example configuration can be used in a **drupal 7** or **drupal
   6** site. In drupal 7 there are plenty of new great things. Not only is
   [image handling](http://drupal.org/node/371374) in core. But also
   there's no need for a regex with capturing for appending the query
   string. Therefore the rewrite rule for the `@drupal` location is
   much simpler.
  
   For using the drupal 7 configuration, uncomment out the:

       include sites-available/drupal7.conf;

   line. And comment out:

       include sites-available/drupal.conf;

   Note that you can use the drupal 6 config with drupal 7. But the
   drupal 7 config is **faster** since there's no regex involved in
   the rewrite and also the location where imagecache files are stored
   has changed in drupal 7. The drupal 6 configuration has no support
   for the new location. So they're interchangable only if **don't use**
   imagecache.
       
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

   4. Support for the [Boost](http://drupal.org/project/boost) module.

   5. Support for virtual hosts. The `example.com` file.

   6. Support for [Sitemaps](http://drupal.org/project/site_map) RSS feeds.

   7. Support for the
      [Filefield Nginx Progress](http://drupal.org/project/filefield_nginx_progress)
      module for the upload progress bar.

   8. Use of **non-capturing** regex for all directives that are not
      rewrites that need to use URI components.1

   9. IPv6 and IPv4 support.
   
   10. Support for **private file** serving in drupal.

   11. Use of UNIX sockets in `/tmp/` subdirectory with permissions
       **700**, i.e., accessible only to the user running the process.
   You may consider the
   [init script](github.com/perusio/php-fastcgi-debian-script) that I
   make available here on github that launches the PHP FastCGI daemon
   and spawns new instances as required.
  
   
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

   1. The use of a `default` configuration file to block all illegal
      `Host` HTTP header requests.

   2. Access control using
      [HTTP Basic Auth](http://wiki.nginx.org/NginxHttpAuthBasicModule)
      for `install.php` and other Drupal sensitive files. The
      configuration expects a password file named `.htpasswd-users` in
      the top nginx configuration directory, usually `/etc/nginx`. I
      provide an empty file. This is also for the **non drush aware**
      version.

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

   3. Support for
      [X-Frame-Options](https://developer.mozilla.org/en/The_X-FRAME-OPTIONS_response_header)
      HTTP header to avoid Clickjacking attacks.

   4. Protection of the upload directory. You can try to bypass the
      UNIX `file` utility or the PHP `Fileinfo` extension and upload a
      fake jpeg:
   
          echo -e "\xff\xd8\xff\xe0\n<?php echo 'hello'; ?>" > test.jpg
      
      If you run `php test.jpg`  you get 'hello'. The fact is that **all
      files** with php extension are either matched by a particular
      location, as is the case for `index.php`, `xmlrpc.php`,
      `update.php` and `install.php` or match the last directive of
      the configuration:

          location ~* ^.+\.php$ {
            return 404; 
          }

      Returning a 404 (Not Found) for every PHP file not matched by
      all the previous locations.

   5. Use of [Strict Transport Security](http://www.chromium.org/sts
      "STS at chromium.org") for enhanced security. It forces during
      the specified period for the configured domain to be contacted
      only over HTTPS. Requires a modern browser to be of use, i.e.,
      **Chrome/Chromium**, **Firefox 4** or **Firefox with
      NoScript**.

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
       
       location ~* protected {
         internal;
       }
  
   Now any attempt to access the files under this directory directly
   will return a 404.

## Installation

   1. Move the old `/etc/nginx` directory to `/etc/nginx.old`.
   
   2. Clone the git repository from github:
   
      `git clone https://github.com/perusio/drupal-with-nginx.git`
   
   3. Edit the `sites-available/example.com` configuration file to
      suit your requirements. Namely replacing example.com with
      **your** domain.
   
   4. Setup the PHP handling method. It can be:
   
      + Upstream HTTP server like Apache with mod_php
      
      + FastCGI process using php-cgi. In this case an
        [init script](https://github.com/perusio/php-fastcgi-debian-script
        "Init script for php-cgi") is
        required. This is how the server is configured out of the
        box. It uses UNIX sockets. You can use TCP sockets if you prefer.
      
      + [PHP FPM](http://www.php-fpm.org "PHP FPM"), this requires you
        to configure your fpm setup, in Debian/Ubuntu this is done in
        the `/etc/php5/fpm` directory.
        
      Check that the socket is properly created and is listening. This
      can be done with `netstat`, like this for UNIX sockets:
      
        `netstat --unix -l`
         
        `netstat -t -l`
   
      It should display the PHP CGI socket.
   
   5. Create the `/etc/nginx/sites-enabled` directory and enable the
      virtual host using one of the methods described below.
    
   6. Reload Nginx:
   
      `/etc/init.d/nginx reload`
   
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

## Acknowledgments

   The great bunch at the [Nginx](http://groups.drupal.org/nginx
   "Nginx Drupal group") group on groups.drupal.org. They've helped me
   sort out the snafus on this config and offered insights on how to
   improve it.

## My other nginx configs on github

   + [WordPress]((https://github.com/perusio/wordpress-nginx "WordPress Nginx
     config")

   + [Chive](https://github.com/perusio/chive-nginx "Chive Nginx
     config")
     
   + [Piwik](https://github.com/perusio/piwik-nginx "Piwik Nginx config")

