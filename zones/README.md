Zones
=====

Use this directory to define zones.
You may turn off any file by changing the suffix (I prefer adding .off)

Limit Zones
-----------

Limit zones for connections using the [limit_conn](http://nginx.org/en/docs/http/ngx_http_limit_conn_module.html) module and for requests using the [limit_req](http://nginx.org/en/docs/http/ngx_http_limit_req_module.html) module can be placed in this folder.

It is suggested to use one file per zone following a naming convention <zone_name>.conf and all .conf files will be included in nginx.conf

Zone names must be unique and they can then be used in the virtual hosts.

MicroCache Zones
----------------

Proxy (Apache) and FastCGI cache zones are also defined here.

