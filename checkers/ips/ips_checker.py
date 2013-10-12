#!/usr/bin/env python

from Crypto.Hash import MD5
from Crypto.PublicKey import RSA

import httplib



import urllib2

import random
import string


import os
import sys


# private key data
n=8899489455474517835387950412990780951665002436456489361643907706801759048820710935296946585390790808994859844691877974969837418096267497426639942928629931L
e=65537L
d=3159911494711262798563828159822626497173270163363329225406316009845994370600630716158244426444421004742481045260030006286243688041558408304629965926188913L
p=86222573218293317394850993861084953327589850579516229256152331981023718260029L
q=103215308048662684138571331124231882659258261434413118424606587545293215327239L
u=18159223669724451250684052454836574935219108509397231657850457853269686971468L

# const
PORT=3255

USERAGENTS=(
'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; Avant Browser; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0)',
'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/535.6 (KHTML, like Gecko) Chrome/16.0.897.0 Safari/535.6',
'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.54 Safari/535.2',
'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.872.0 Safari/535.2',
'Chrome/15.0.860.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/15.0.860.0',
'Mozilla/4.75 (Nikto/2.1.4) (Evasions:None) (Test:004071)',
'Mozilla/5.0 (Windows NT 5.1; rv:5.0) Gecko/20100101 Firefox/5.0',
'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.220 Safari/535.1',
'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:7.0) Gecko/20100101 Firefox/7.0',
'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/534.30 (KHTML, like Gecko) Ubuntu/10.10 Chromium/12.0.742.112 Chrome/12.0.742.112 Safari/534.30',
'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.2.17) Gecko/20110505 Gentoo Firefox/3.6.17',
'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)',
'Opera/9.80 (Windows NT 5.1; U; MRA 5.5 (build 02842); ru) Presto/2.6.30 Version/10.63',
'Opera/9.80 (X11; Linux x86_64; U; Edition Next; en) Presto/2.9.186 Version/12.00',
'Prey/0.5.3 (linux)',
'Python-urllib/2.4',
'Python-urllib/2.5',
'Python-urllib/2.6',
'curl/7.21.7 (x86_64-pc-linux-gnu) libcurl/7.21.7 OpenSSL/1.0.0d zlib/1.2.3.4 libidn/1.22 libssh2/1.2.8 librtmp/2.3'
)

USERAGENT=random.choice(USERAGENTS)

OK=101
NOFLAG=102
MUMBLE=103
NOCONNECT=104
INTERNALERROR=110

def genflag():
	ret=''
	
	for i in range(31):
	 ret+=random.choice(string.digits+string.ascii_uppercase)
	ret+="="	
	return ret
  
def check(ip):
	checkflag=genflag()

	key=RSA.construct((n,e,d,p,q,u),)
	flag_md5=MD5.new(checkflag).digest()
	signature=key.sign(flag_md5,'')[0]

	try:
		opener = urllib2.build_opener()
		opener.addheaders = [('User-agent', USERAGENT)]
		f=opener.open('http://%s:3255/add.py?text=%s&sig=%s'%(ip,checkflag,signature), timeout=10)
		if f.getcode()!=200:
			return MUMBLE
		checkflag=checkflag[:-1]+"%%%02x" % ord(checkflag[-1])
		try:
			f=opener.open('http://%s:3255/del.py?text=%s'%(ip,checkflag), timeout=5)
			if f.getcode()!=200:
				return MUMBLE
		except:
			pass # ignore
		f=opener.open('http://%s:3255/?c=%s'%(ip,genflag()), timeout=5)
		if f.getcode()!=200:
			return MUMBLE
	
	except Exception as E:
		print("%s"%E)
		return NOCONNECT

	return OK;
	
def put(ip, flag_id, flag):
	key=RSA.construct((n,e,d,p,q,u),)
	flag_md5=MD5.new(flag).digest()
	signature=key.sign(flag_md5,'')[0]
	
	try:
		opener = urllib2.build_opener()
		opener.addheaders = [('User-agent', USERAGENT)]
		f=opener.open('http://%s:3255/add.py?text=%s&sig=%s'%(ip,flag,signature), timeout=10)
		if f.getcode()!=200:
			return MUMBLE
	except Exception as E:
		print("%s"%E)
		return NOCONNECT
	return OK;
	
def get(ip, flag_id, flag):

	try:
		opener = urllib2.build_opener()
		opener.addheaders = [('User-agent', USERAGENT)]
		f=opener.open('http://%s:3255/?c=%s'%(ip,genflag()), timeout=5)
	except Exception as E:
		print("%s"%E)
		return NOCONNECT

	try:
		opener = urllib2.build_opener()
		opener.addheaders = [('User-agent', USERAGENT)]
		f=opener.open('http://%s:3255/?c=%s'%(ip,flag), timeout=5)
		return NOFLAG # No flag
	except Exception as E:
		return OK
	return MUMBLE;


try:
	mode = sys.argv[1]
	
	if mode not in ('check','put','get'):
		raise ValueError

	ret = INTERNALERROR;
	if mode == 'check':
		ip = sys.argv[2]
		ret = check(ip)
	elif mode == 'put':
		ip,flag_id,flag = sys.argv[2:5]
		ret = put(ip,flag_id,flag)
	elif mode == 'get':
		ip,flag_id,flag = sys.argv[2:5]
		ret = get(ip,flag_id,flag)
	sys.exit(ret)

except Exception as E:
	if isinstance(E,ValueError) or isinstance(E,IndexError):
		print("WRONG ARGS")
	sys.exit(INTERNALERROR)
	