# -*- mode: nginx; mode: flyspell-prog; mode: autopair; ispell-current-dictionary: american -*-
### Configuration for example.com.

## Rewrite server block.
server {
    ## This is to avoid the spurious if for sub-domain name
    ## rewriting. See http://wiki.nginx.org/Pitfalls#Server_Name.
    server_name www.example.com;
    rewrite ^ $scheme://example.com$request_uri? permanent;
} # server domain rewrite.


## HTTP server.
server {
    listen [::]:80;
    server_name example.com;
    limit_conn arbeit 16;

    ## Access and error logs.
    access_log  /var/log/nginx/example.com_access.log;
    error_log   /var/log/nginx/example.com_error.log;

    ## Include the blacklist.conf file.
    include sites-available/blacklist.conf;

    ## Disable all methods besides HEAD, GET and POST.
    if ($request_method !~ ^(GET|HEAD|POST)$ ) {
        return 444;
    }

    ## Filesystem root of the site and index.
    root /var/www/sites/example.com;
    index index.php;
    
    ## Use a static index file if available.
    include sites-available/static_index.conf;
    
    ## Include all Drupal stuff.
    include sites-available/drupal.conf;

    ## For D7. Use this instead.
    #include sites-available/drupal7.conf;
    
    ## For upload progress to work. From the README of the
    ## filefield_nginx_progress module.
    location ~ (.*)/x-progress-id:(\w*) {
        rewrite ^(.*)/x-progress-id:(\w*)  $1?X-Progress-ID=$2;
    }

    location ^~ /progress {
        report_uploads uploads;
    }

    ## Including the php-fpm status and ping pages config.
    ## Uncomment to enable if you're running php-fpm.
    #include php_fpm_status.conf;

} # HTTP server


## HTTPS server.
server {
    listen [::]:443 ssl;
    server_name example.com;
    limit_conn arbeit 10;

    ## Access and error logs.
    access_log  /var/log/nginx/example.com_access.log;
    error_log   /var/log/nginx/example.com_error.log;

    ## Keep alive timeout set to a greater value for SSL/TLS.
    keepalive_timeout 75 75;
    
    ## Include the blacklist.conf file.
    include sites-available/blacklist.conf;

    ## Disable all methods besides HEAD, GET and POST.
    if ($request_method !~ ^(GET|HEAD|POST)$ ) {
        return 444;
    }

    ## See the keepalive_timeout directive in nginx.conf.
    ## Server certificate and key.
    ssl_certificate /etc/ssl/certs/example-cert.pem;
    ssl_certificate_key /etc/ssl/private/example.key;
    
    ## Strict Transport Security header for enhanced security. See
    ## http://www.chromium.org/sts. I've set it to 2 hours; set it to
    ## whichever age you want.
    add_header Strict-Transport-Security "max-age=7200";

    root /var/www/sites/example.com/;
    index index.php index.html;

    ## Include all Drupal stuff.
    include sites-available/drupal.conf;

    ## For D7. Use this instead.
    #include sites-available/drupal7.conf;
    
    ## For upload progress to work. From the README of the
    ## filefield_nginx_progress module.
    location ~ (.*)/x-progress-id:(\w*) {
        rewrite ^(.*)/x-progress-id:(\w*)  $1?X-Progress-ID=$2;
    }

    location ^~ /progress {
        report_uploads uploads;
    }

    ## Including the php-fpm status and ping pages config.
    ## Uncomment to enable if you're running php-fpm.
    #include php_fpm_status.conf;

} # HTTPS server
