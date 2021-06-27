#!/usr/bin/env python
#coding:utf-8
import memcache
m = memcache.Client(['127.0.0.1:11211'], debug=True)
for i in range(10):
    m.set("key%d" % i,"v%d" % i)
    ret = m.get('key%d' % i)
    print ret
