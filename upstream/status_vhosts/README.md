Status vHosts
=============

Each file defines the locations for a particular upstream's ping/status pages.

This needs to be included in the virtual hosts in order to check availability according to use (if one vHost uses a backend, it should include its check locations).

All .conf files are included in the default server so any backend can be checked by IP address (e.g. from an AWS ELB).

A sample file is provided to check the phpcgi_unix backend with two servers

The backend must be configured appropriately to respond to the tests.

Suggestions:
-----------

Locations should be use the following naming convention 

```
/upstream/<backend>/<operation>[/<pool>]
```

Where:
  * `<backend>`: is the name of the backend being tested
  * `<operation>`: ping, status, etc. As supported by the backend.
  * `<pool>`: Optionally test a specific server in the backend.
