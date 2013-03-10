Introduction
============

### Arnold: *the provisionator*

This is the start of a self service provisioning system.

It currently has these functions:

* Provide a REST-like API to manage Hiera YAML files with a certain structure
* Provides a graphical web interface to manage Hiera YAML files
* Provides a command line interface to manage (create, list) Hiera YAML files
* Provides a few Puppet functions to read these files and:
  * populate glabal variables (like facts or an ENC)
  * apply classes to a node
* Provides a pluggable backend for provisioning. Out of the box are:
  * Null provisioner: does nothing when called
  * Cloud Provisioner: calls out to Puppet's Cloud Provisioner to spin up, install, and classify new instances

This was originally designed to provide a REST API for provisioning nodes with Razor. With the design of Razor
being such that the only bit of information that's known before & after is the MAC address, Arnold creates a
Hiera datasource hierarchy allowing classification via either the certname or the MAC address. Because Hiera
is so dependent on filesystem paths, this is accomplished by creating symlinks named by the certname and the
MAC address. This architecture is slightly clumsy, so it may not last.

Configuration
=============

* Installing
    * It's a Puppet module, yo! Install via `puppet module install binford2k-arnold` or copy the `binford2k-arnold` subdirectory to your modulepath and rename it to `arnold`.
* Setup the server
  1. Classify your server with `arnold::provisionator` and apply.
  2. Configure by editing `/etc/arnold/config.yaml`
      * A sample configuration file is included as <a href="doc/config.yaml">`doc/config.yaml`</a>.
      * The puppet module is simplistic and doesn't allow for editing this file, so you should currently modify the files in the module.
      * You will probably want to point the `datadir` to wherever you've configured Hiera to use.
      * You may configure Arnold to reuse Puppet certs if you wish.
      * If you choose to generate your own SSL certs, drop them in /etc/arnold/certs
          * `openssl genrsa -out server.key 1024`
          * `openssl req -new -key server.key -out server.csr`
          * `openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt`
      * Classes described in `config.yaml` may be applied to nodes and will be listed in the GUI.
  3. Point a web browser at the configured port
      * Clicky clicky
      * List nodes, create nodes, modify nodes, etc
  4. Enable arnold for clients:
      * In `site.pp` on your master, outside of any node definitions, simply call the `arnold()` function.

Provisioner backend configuration
=============

Currently only the CloudProvisioner provisioning backend exits. You can enable it by
adding a stanza like this to your `config.yaml`

    backend:      CloudProvisioner
    keyfile:      ~/.ssh/private_key.pem
    enc_password: <password>

If a backend is not configured, Arnold will not perform any provisioning actions.
It is entirely useful like this, as it will instead only manage the Hiera datafiles.

Usage
=============

Besides the web frontend, you can interact with Arnold via the command line and a REST-like API.

### REST-like API

Send a JSON formatted payload to Arnold's enpoints that looks like:

    {
      'macaddr'    => '00:0C:29:D1:03:A4',
      'name'       => 'this.is.another.brand.new.system',
      'parameters' => {
                        'booga'   => 'wooga',
                        'fiddle'  => 'faddle',
                      },
      'classes'    => [ 'test', 'mysql', 'ntp' ],
    }

The known endpoints are:

* Create a node:
  * `/api/v1/create`
* Retrieve a node's configuration:
  * `/api/v1/:guid`
* Delete a node:
  * `/api/v1/remove/:guid`

Sample code is included as <a href="doc/postjson.rb">`doc/postjson.rb`</a>.

### Command Line

    Usage:
        * arnold help
        * arnold list
        * arnold show <guid>
        * arnold remove <guid>
        * arnold new [name=<name>] [macaddr=<macaddr>] [template=<template>] [group=<group>] [classes=<class1,class2,...>] [param1=value1]...

Limitations
============

* It does not currently manage parameterized classes.

Contact
=======

* Author: Ben Ford
* Email: ben.ford@puppetlabs.com
* Twitter: @binford2k
* IRC (Freenode): binford2k

Credit
=======

The development of this code was sponsored by FBL Financial.

License
=======

Copyright (c) 2013 Puppet Labs, info@puppetlabs.com  
Copyright (c) 2013 FBL Financial, puppet@fblfinancial.com

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
