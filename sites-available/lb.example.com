# -*- mode: nginx; mode: flyspell-prog;  ispell-local-dictionary: "american" -*-

### Load balancer configuration.

## Return (no rewrite) server block.
server {
    ## This is to avoid the spurious if for sub-domain name
    ## "rewriting".
    listen [::]:80;
    server_name example.com;
    return 301 $scheme://example.com$request_uri;

} # server domain return.

## HTTP server.
server {
    listen [::]:80;
    server_name example.com;
    limit_conn arbeit 64;

    ## Access and error logs.
    access_log /var/log/nginx/lb-example.com_access.log;
    error_log /var/log/nginx/lb-example.com_error.log;

    ## See the blacklist.conf file at the parent dir: /etc/nginx.
    ## Deny access based on the User-Agent header.
    if ($bad_bot) {
        return 444;
    }
    ## Deny access based on the Referer header.
    if ($bad_referer) {
        return 444;
    }

    ## Including the Nginx stub status page for having stats about
    ## Nginx activity.
    include nginx_status_vhost.conf;

    ## Proxy all requests to the backends.
    location / {
        ## Include the proxy cache.
        include sites-available/microcache_long_proxy.conf;
        ## Keepalive to backend.
        proxy_http_version 1.1;
        ## Forward the protocol upstream.
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://backend_web$request_uri;
        # proxy_redirect http://example.com /;
        ## How to deal with 'bad' backends,
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_504;
        ## Timeout settings.
        proxy_intercept_errors on;
        proxy_connect_timeout 70s;
        proxy_send_timeout 10m;
        proxy_read_timeout 20m;
        ## Proxy buffer tuning.
        proxy_buffer_size 32k;
        proxy_buffers 64 4k;
        proxy_busy_buffers_size 64k;
        proxy_max_temp_file_size 6M;
    }

    ## Backend testing/reporting location.
    location = /lbtest {
        if ($arg_k != 581c6b3d) {
            return 404;
        }
        proxy_pass http://backend_web$request_uri;
    }

    ## Serve aggregated JS and CSS files.
    location ^~ /sites/default/files/js/js_ {
        location ~* ^/sites/default/files/js/js_[[:alnum:]]+\.js$ {
            ## Include the proxy cache.
            include sites-available/microcache_long_proxy.conf;
        }
    }

    location ^~ /sites/default/files/css/css_ {
        location ~* ^/sites/default/files/css/css_[[:alnum:]]+\.css$ {
            ## Include the proxy cache.
            include sites-available/microcache_long_proxy.conf;
        }
    }

    ## Miscellaneous CSS and JS.
    location ~* ^.*\.(?:css|js)$ {
        ## Include the proxy cache.
        include sites-available/microcache_long_proxy.conf;
    }

    ## MP3 and Ogg/Vorbis files are served using AIO when supported. Your OS must support it.
    location ^~ /sites/default/files/audio/mp3 {
        location ~* ^/sites/default/files/audio/mp3/.*\.mp3$ {
            directio 4k; # for XFS
            ## If you're using ext3 or similar uncomment the line below and comment the above.
            #directio 512; # for ext3 or similar (block alignments)
            tcp_nopush off;
            aio on;
            output_buffers 1 2M;
        }
    }

    location ^~ /sites/default/files/audio/ogg {
        location ~* ^/sites/default/files/audio/ogg/.*\.ogg$ {
            directio 4k; # for XFS
            ## If you're using ext3 or similar uncomment the line below and comment the above.
            #directio 512; # for ext3 or similar (block alignments)
            tcp_nopush off;
            aio on;
            output_buffers 1 2M;
        }
    }

    ## Video serving location for videos.
    ## Pseudo streaming of FLV files:
    ## http://wiki.nginx.org/HttpFlvStreamModule.
    location ^~ /sites/default/files/video/flv {
        location ~* ^/sites/default/files/video/flv/.*\.flv$ {
            flv;
        }
    }

    ## Pseudo streaming of H264/AAC files. This requires an Nginx
    ## version greater or equal to 1.0.7 for the stable branch and
    ## greater or equal to 1.1.3 for the development branch.
    ## Cf. http://nginx.org/en/docs/http/ngx_http_mp4_module.html.
    location ^~ /sites/default/files/video/mp4 { # videos
        location ~* ^/sites/default/files/video/mp4/.*\.(?:mp4|mov)$ {
            mp4;
            mp4_buffer_size     1M;
            mp4_max_buffer_size 5M;
        }
    }

    location ^~ /sites/default/files/audio/m4a { # audios
        location ~* ^/sites/default/files/audio/m4a/.*\.m4a$ {
            mp4;
            mp4_buffer_size     1M;
            mp4_max_buffer_size 5M;
        }
    }

} # HTTP server

## HTTPS server.
server {
    listen [::]:443 ssl;
    server_name example.com;
    limit_conn arbeit 64;

    ## Access and error logs.
    access_log /var/log/nginx/lb.example.com_access.log;
    error_log /var/log/nginx/lb.example.com_error.log;

    ## Keep alive timeout set to a greater value for SSL/TLS.
    keepalive_timeout 75 75;

    ## See the keepalive_timeout directive in nginx.conf.
    ## Server certificate and key.
    ssl_certificate /etc/ssl/certs/example.com_cert.pem;
    ssl_certificate_key /etc/ssl/private/example.com_key.pem;

    ## Strict Transport Security header for enhanced security. See
    ## http://www.chromium.org/sts. I've set it to 2 hours; set it to
    ## whichever age you want.
    #add_header Strict-Transport-Security "max-age=7200";

    ## See the blacklist.conf file at the parent dir: /etc/nginx.
    ## Deny access based on the User-Agent header.
    if ($bad_bot) {
        return 444;
    }
    ## Deny access based on the Referer header.
    if ($bad_referer) {
        return 444;
    }

    ## Including the Nginx stub status page for having stats about
    ## Nginx activity.
    include nginx_status_vhost.conf;

    ## Proxy all requests to the backends.
    location / {
        ## Include the proxy cache.
        include sites-available/microcache_long_proxy.conf;
        ## Keepalive to backend.
        proxy_http_version 1.1;
        proxy_pass http://backend_web$request_uri;
        ## Send a special header detailing the scheme.
        proxy_set_header X-Forwarded-Proto $scheme;
        # proxy_redirect http://example.com /;
        ## How to deal with 'bad' backends,
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_504;
        ## Timeout settings.
        proxy_intercept_errors on;
        proxy_connect_timeout 70s;
        proxy_send_timeout 10m;
        proxy_read_timeout 20m;
        ## Proxy buffer tuning.
        proxy_buffer_size 32k;
        proxy_buffers 64 4k;
        proxy_busy_buffers_size 64k;
        proxy_max_temp_file_size 6M;
    }

    ## Backend testing/reporting location.
    location = /lbtest {
        if ($arg_k != 581c6b3d) {
            return 404;
        }
        proxy_pass http://backend_web$request_uri;
    }

    ## Serve aggregated JS and CSS files.
    location ^~ /sites/default/files/js/js_ {
        location ~* ^/sites/default/files/js/js_[[:alnum:]]+\.js$ {
            ## Include the proxy cache.
            include sites-available/microcache_long_proxy.conf;
        }
    }

    location ^~ /sites/default/files/css/css_ {
        location ~* ^/sites/default/files/css/css_[[:alnum:]]+\.css$ {
            ## Include the proxy cache.
            include sites-available/microcache_long_proxy.conf;
        }
    }

    ## Miscellaneous CSS and JS.
    location ~* ^.*\.(?:css|js)$ {
        ## Include the proxy cache.
        include sites-available/microcache_long_proxy.conf;
    }

} # HTTP server

