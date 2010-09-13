# -*- mode: conf; mode: flyspell-prog; mode: autopair; ispell-current-dictionary: american -*-
# -*- mode: conf; mode: flyspell-prog; mode: autopair; ispell-local-dictionary: "american" -*-
### Configuration for example.com.
 
server {
       ## This is to avoid the spurious if for sub-domain name
       ## rewriting. See http://wiki.nginx.org/Pitfalls#Server_Name.
       server_name www.example.com;
       rewrite ^ $scheme://example.com$request_uri permanent;
} # server domain rewrite.



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

        # For upload progress to work. From the README of the
        # filefield_nginx_progress module.
        location ~ (.*)/x-progress-id:(\w*) {
                 rewrite ^(.*)/x-progress-id:(\w*)  $1?X-Progress-ID=$2;
        }

        location ^~ /progress {
            report_uploads uploads;
        }
        
        # # The 404 is signaled through a static page.
	# error_page  404  /404.html;

        # ## All server error pages go to 50x.html at the document root.
	# error_page 500 502 503 504  /50x.html;
	# location = /50x.html {
	# 	root   /var/www/nginx-default;
	# }
} # server

