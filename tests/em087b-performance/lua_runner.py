"""Run standalone differential tests using the system Lua 5.4 library (not Factorio)."""
import ctypes as c,sys
l=c.CDLL('liblua5.4.so.0'); l.luaL_newstate.restype=c.c_void_p;l.luaL_openlibs.argtypes=[c.c_void_p];l.luaL_loadfilex.argtypes=[c.c_void_p,c.c_char_p,c.c_char_p];l.lua_pcallk.argtypes=[c.c_void_p,c.c_int,c.c_int,c.c_int,c.c_longlong,c.c_void_p];l.lua_tolstring.argtypes=[c.c_void_p,c.c_int,c.POINTER(c.c_size_t)];l.lua_tolstring.restype=c.c_char_p;l.lua_close.argtypes=[c.c_void_p]
L=l.luaL_newstate();l.luaL_openlibs(L)
rc=l.luaL_loadfilex(L,sys.argv[1].encode(),None)
if not rc:rc=l.lua_pcallk(L,0,0,0,0,None)
if rc: print(l.lua_tolstring(L,-1,None).decode(),file=sys.stderr)
l.lua_close(L);sys.exit(rc!=0)
