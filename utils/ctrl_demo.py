from ctypes import *
from datetime import datetime
so_file = "/home/earl_07/corundum-forked/utils/mqnic.so"

now = datetime.now()
get_cookie = CDLL(so_file)
print(type(get_cookie))
print(get_cookie.get_cookie())
print(get_cookie.get_token())
print("%02d %02d", now.microsecond, now.microsecond)
