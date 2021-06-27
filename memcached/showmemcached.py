#!/usr/bin/python3
import memcache # pip install python-memcached
mc = memcache.Client(['10.0.0.101:11211','10.0.0.102:11211'], debug=True)
#print('-' * 30)
# 查看全部key
#for x in mc.get_stats('items'):  # stats items 返回 items:5:number 1
#    print(x)
print('-' * 30)

for x in mc.get_stats('cachedump 5 0'):  # stats cachedump 5 0 # 5和上面的items返回的值有关；0表示全部
    print(x)
