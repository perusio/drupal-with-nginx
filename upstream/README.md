UpStream Blocks
===============

Upstream blocks define the backends for Nginx.
Any file in this directory with the .conf suffix will be included in nginx.conf.

Some sample configurations are provided

| File | Contents |
|------|----------|
| phpapache.conf.sample | Upstream HTTP server like Apache with mod_php. Nginx will need to work as reverse proxy in this case |
| phpcgi_tcp.conf.sample | PHP-FPM configured to listen on Unix sockets |
| phpcgi_unix.conf.sample | PHP-FPM configured to listen on TCP sockets |

Suggestions
-----------

* One file per backend, named `<backend>.conf`
* Within the file there should be the following:
  * One upstream block named `<backend>`, defining the backend's servers and policy.
  * If the backend servers support ping/status:
    * One upstream block per server/pool named `<backend>_<pool>`
    * One Geo variable named `$acl_<backend>_status` that will allow/deny access to the ping/status page (used in the locations defined under status_vhosts)
