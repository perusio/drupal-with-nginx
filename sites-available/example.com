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
    limit_conn arbeit 10;

    # Parameterization using hostname of access and log filenames.
    access_log  /var/log/nginx/example.com_access.log;
    error_log   /var/log/nginx/example.com_error.log;

    # Include the blacklist.conf file.
    include sites-available/blacklist.conf;

    # Disable all methods besides HEAD, GET and POST.
    if ($request_method !~ ^(GET|HEAD|POST)$ ) {
        return 444;
    }

    root  /var/www/sites/example.com/;
    index index.php index.html;

    # Include all Drupal stuff.
    include sites-available/drupal.conf;

    # For D7. Use this instead.
    #include sites-available/drupal7.conf;
    
    # For upload progress to work. From the README of the
    # filefield_nginx_progress module.
    location ~ (.*)/x-progress-id:(\w*) {
        rewrite ^(.*)/x-progress-id:(\w*)  $1?X-Progress-ID=$2;
    }

    location ^~ /progress {
        report_uploads uploads;
    }
    
} # HTTP server


## HTTPS server.
server {
    listen [::]:443;
    server_name example.com;
    limit_conn arbeit 10;
    # Parameterization using hostname of access and log filenames.
    access_log  /var/log/nginx/example.com_access.log;
    error_log   /var/log/nginx/example.com_error.log;

    # Include the blacklist.conf file.
    include sites-available/blacklist.conf;

    # Disable all methods besides HEAD, GET and POST.
    if ($request_method !~ ^(GET|HEAD|POST)$ ) {
        return 444;
    }

    ## See the keepalive_timeout directive in nginx.conf.
    ## Server certificate and key.
    ssl_certificate /etc/ssl/certs/example-cert.pem;
    ssl_certificate_key /etc/ssl/private/example.key;
    
    ## Use a SSL/TLS cache for SSL session resume.
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    ## Strict Transport Security header for enhanced security. See
    ## http://www.chromium.org/sts. I've set it to 2 hours; set it to
    ## whichever age you want.
    add_header Strict-Transport-Security "max-age=7200";

    root /var/www/sites/example.com/;
    index index.php index.html;

    # Include all Drupal stuff.
    include sites-available/drupal.conf;

    # For D7. Use this instead.
    #include sites-available/drupal7.conf;
    
    # For upload progress to work. From the README of the
    # filefield_nginx_progress module.
    location ~ (.*)/x-progress-id:(\w*) {
        rewrite ^(.*)/x-progress-id:(\w*)  $1?X-Progress-ID=$2;
    }

    location ^~ /progress {
        report_uploads uploads;
    }

} # HTTPS server
