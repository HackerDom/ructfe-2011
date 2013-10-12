#!/bin/bash

# CMS
apt-get install libcrypt-ssleay-perl libcrypt-openssl-rsa-perl libgmp3-dev

wget http://search.cpan.org/CPAN/authors/id/S/SI/SISYPHUS/Math-GMPz-0.32.tar.gz
tar -xvf Math-GMPz-0.32.tar.gz
cd Math-GMPz-0.32
perl Makefile.PL
make && make test && make install 

# FFD9
# cpan
# enter: http://cpan.org
# cpan> install Mojolicious
# cpan> i Mojolicious

apt-get install libbarcode-code128-perl libfile-slurp-perl libgd-gd2-perl

# IPS
apt-get install python-crypto

# FastMusic
apt-get install ruby1.9.1 ruby1.9.1-dev libcurl4-openssl-dev rubygems1.9.1
gem install curb

