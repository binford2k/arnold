#! /bin/sh

mkdir -p /usr/local/share/arnold
cp -a arnold/files/{arnold.rb,public,views} /usr/local/share/arnold
ln -s /usr/local/share/arnold/arnold.rb /usr/local/bin/arnold

mkdir -p /etc/arnold/data
cp -r arnold/files/config/{config.yaml,certs} /etc/arnold
