Introduction
============

### Arnold: *the provisionator*

This is the start of a Razor provisioning system.

Currently, all it does is provide a web service that will read & write YAML files
and a class that will call `hiera_include()` to read them and apply classes to a node.

Very soon, I plan to provide Razor functionality to spin up new instances after
classifying them, and then it will be a simplistic self service provisioner.

Configuration
=============

* Installing
    * It's a Puppet module, yo! Copy the `arnold` subdirectory to your modulepath.
    * Alternately, you can install by hand by running the little installer script.
* Setup the server
  1. Classify your server with `arnold::provisionator` and apply.
  2. Configure by editing `/etc/arnold/config.yaml`
      * You will probably want to point the `datadir` to wherever you've configured Hiera to use.
      * You may configure Arnold to reuse Puppet certs if you wish.
      * If you choose to generate your own SSL certs, drop them in /etc/arnold/certs
          * `openssl genrsa -out server.key 1024`
          * `openssl req -new -key server.key -out server.csr`
          * `openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt`
  3. Point a web browser at the configured port
      * Clicky clicky
      * List nodes, create nodes, modify nodes, etc
* Setup the clients
    * Classify new nodes with `arnold`
        * You may want to put this in the `default` group or node.
 
Limitations
============

* It does not currently manage parameters or parameterized classes.
* Razor support is not yet included.

Contact
=======

* Author: Ben Ford
* Email: ben.ford@puppetlabs.com
* Twitter: @binford2k
* IRC (Freenode): binford2k

Credit
=======

The development of this code was sponsored by the FBL Financial.

License
=======

Copyright (c) 2013 Puppet Labs, info@puppetlabs.com  
Copyright (c) 2013 FBL Financial, MikeDowning@fblfinancial.com

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
