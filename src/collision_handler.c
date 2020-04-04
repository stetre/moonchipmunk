/* The MIT License (MIT)
 *
 * Copyright (c) 2020 Stefano Trettel
 *
 * Software repository: MoonChipmunk, https://github.com/stetre/moonchipmunk
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "internal.h"

static int freecollision_handler(lua_State *L, ud_t *ud)
    {
    //collision_handler_t *handler = (collision_handler_t*)ud->handle;
    if(!freeuserdata(L, ud, "collision_handler")) return 0;
    return 0;
    }

int newcollision_handler(lua_State *L, collision_handler_t *handler, space_t *space)
    {
    ud_t *ud;
    if(userdata(handler)) /* already in */
        return pushcollision_handler(L, handler);
    ud = newuserdata(L, handler, COLLISION_HANDLER_MT, "collision_handler");
    ud->parent_ud = userdata(space);
    ud->destructor = freecollision_handler;
    handler->userData = ud;
    return 1;
    }

static int GetTypes(lua_State *L)
    {
    collision_handler_t *handler = checkcollision_handler(L, 1, NULL);
    lua_pushinteger(L, handler->typeA);
    lua_pushinteger(L, handler->typeB);
    return 2;
    }

static cpBool BeginFunc(cpArbiter *arbiter, space_t *space, cpDataPointer userData)
    {
    int rc;
    cpBool res;
    lua_State *L = moonchipmunk_L;
    ud_t *ud = (ud_t*)userData;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    pusharbiter(L, arbiter);
    pushspace(L, space);
    rc = lua_pcall(L, 2, 1, 0);
    invalidatearbiter(L, arbiter);
    if(rc != LUA_OK) { lua_error(L); return 0; }
    res = lua_toboolean(L, -1);
    lua_settop(L, top);
    return res;
    }

static cpBool PreSolveFunc(cpArbiter *arbiter, space_t *space, cpDataPointer userData)
    {
    int rc;
    cpBool res;
    lua_State *L = moonchipmunk_L;
    ud_t *ud = (ud_t*)userData;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref2);
    pusharbiter(L, arbiter);
    pushspace(L, space);
    rc = lua_pcall(L, 2, 1, 0);
    invalidatearbiter(L, arbiter);
    if(rc != LUA_OK) { lua_error(L); return 0; }
    res = lua_toboolean(L, -1);
    lua_settop(L, top);
    return res;
    }

static void PostSolveFunc(cpArbiter *arbiter, space_t *space, cpDataPointer userData)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    ud_t *ud = (ud_t*)userData;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref3);
    pusharbiter(L, arbiter);
    pushspace(L, space);
    rc = lua_pcall(L, 2, 0, 0);
    invalidatearbiter(L, arbiter);
    if(rc != LUA_OK) { lua_error(L); return; }
    lua_settop(L, top);
    return;
    }

static void SeparateFunc(cpArbiter *arbiter, space_t *space, cpDataPointer userData)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    ud_t *ud = (ud_t*)userData;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref4);
    pusharbiter(L, arbiter);
    pushspace(L, space);
    rc = lua_pcall(L, 2, 0, 0);
    invalidatearbiter(L, arbiter);
    if(rc != LUA_OK)
        { lua_error(L); return; }
    lua_settop(L, top);
    return;
    }

static int SetBeginFunc(lua_State *L)
    {
    ud_t *ud;
    collision_handler_t *handler = checkcollision_handler(L, 1, &ud);
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref1);
    handler->beginFunc = BeginFunc;
    return 0;
    }

static int SetPreSolveFunc(lua_State *L)
    {
    ud_t *ud;
    collision_handler_t *handler = checkcollision_handler(L, 1, &ud);
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref2);
    handler->preSolveFunc = PreSolveFunc;
    return 0;
    }

static int SetPostSolveFunc(lua_State *L)
    {
    ud_t *ud;
    collision_handler_t *handler = checkcollision_handler(L, 1, &ud);
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref3);
    handler->postSolveFunc = PostSolveFunc;
    return 0;
    }

static int SetSeparateFunc(lua_State *L)
    {
    ud_t *ud;
    collision_handler_t *handler = checkcollision_handler(L, 1, &ud);
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref4);
    handler->separateFunc = SeparateFunc;
    return 0;
    }


RAW_FUNC(collision_handler)
PARENT_FUNC(collision_handler)
DESTROY_FUNC(collision_handler)

static const struct luaL_Reg Methods[] = 
    {
        { "raw", Raw },
        { "parent", Parent },
        { "free", Destroy },
        { "get_types", GetTypes },
        { "set_begin_func", SetBeginFunc },
        { "set_pre_solve_func", SetPreSolveFunc },
        { "set_post_solve_func", SetPostSolveFunc },
        { "set_separate_func", SetSeparateFunc },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { NULL, NULL } /* sentinel */
    };


void moonchipmunk_open_collision_handler(lua_State *L)
    {
    udata_define(L, COLLISION_HANDLER_MT, Methods, MetaMethods);
    luaL_setfuncs(L, Functions, 0);
    }

