#! /usr/bin/env bash
# DEPRECATED. This was a first attempt at a provisioner. Now you ought to use the ansible playbook and provisioner instead.

# Install loris in a CentOS 7 box

# install all yum packages
yum -y update
yum -y install python-devel httpd httpd-devel libjpeg-turbo libjpeg-turbo-devel freetype freetype-devel zlib-devel libtiff-devel git unzip

# install pip
wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
python get-pip.py

# install wsgi
wget https://github.com/GrahamDumpleton/mod_wsgi/archive/4.4.13.tar.gz -O mod_wsgi.tar.gz
tar -zxf mod_wsgi.tar.gz
cd mod_wsgi-4.4.13
./configure
make
make install
cd ~

# install pip dependencies
pip install Werkzeug Pillow

# install kakadu
wget http://kakadusoftware.com/wp-content/uploads/2014/06/KDU77_Demo_Apps_for_Linux-x86-64_150710.zip

unzip KDU77_Demo_Apps_for_Linux-x86-64_150710.zip

mkdir /opt/kdu
cp KDU77_Demo_Apps_for_Linux-x86-64_150710/* /opt/kdu/.

sh -c 'echo "/opt/kdu" > /etc/ld.so.conf.d/kdu.conf'
sh -c 'echo "PATH=\$PATH:/opt/kdu" > /etc/profile.d/kdu.sh'

# install loris
useradd -d /var/www/loris -s /sbin/false loris
git clone https://github.com/pulibrary/loris.git
cd loris
python setup.py install --kdu-expand /opt/kdu/kdu_expand --libkdu /opt/kdu
cd ~

# configure Apache
sh -c "cat >/etc/httpd/conf.d/loris.conf" <<'EOF'
ExpiresActive On
ExpiresDefault "access plus 5184000 seconds"

AllowEncodedSlashes On

LoadModule wsgi_module modules/mod_wsgi.so

WSGIDaemonProcess loris2 user=loris group=loris processes=10 threads=15 maximum-requests=10000
WSGIScriptAlias /loris /var/www/loris2/loris2.wsgi
WSGIProcessGroup loris2
EOF

systemctl enable httpd.service
service httpd start

# Poke hole in the firewall
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

# Install openseadragon demo
git clone https://github.com/jronallo/loris-openseadragon-demo.git
cp -r loris-openseadragon-demo/* /var/www/html/.
mkdir -p /usr/local/share/images
cp -r loris-openseadragon-demo/samples/* /usr/local/share/images/.

echo 'On the host machine go to http://127.0.0.1:8080/ and you should see an openseadragon viewer for an insect.'
