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

#define GLMATH_COMPAT (tovec2 != LUA_NOREF)
/* References to the MoonGLMATH functions used to convert pushed values to glmath objects. */
static int tovec2 = LUA_NOREF;
static int tovec4 = LUA_NOREF;
static int tomat2x3 = LUA_NOREF;
static int tobox2 = LUA_NOREF;


int isglmathcompat(void)
    { return GLMATH_COMPAT; }

int glmathcompat(lua_State *L, int on)
    {
    if(on)
        {
        if(GLMATH_COMPAT) return 0; /* already enabled */
        if(luaL_dostring(L, "return require('moonglmath').tovec2") != 0) lua_error(L);
        tovec2 = luaL_ref(L, LUA_REGISTRYINDEX);
        if(luaL_dostring(L, "return require('moonglmath').tovec4") != 0) lua_error(L);
        tovec4 = luaL_ref(L, LUA_REGISTRYINDEX);
        if(luaL_dostring(L, "return require('moonglmath').tomat2x3") != 0) lua_error(L);
        tomat2x3 = luaL_ref(L, LUA_REGISTRYINDEX);
        if(luaL_dostring(L, "return require('moonglmath').tobox2") != 0) lua_error(L);
        tobox2 = luaL_ref(L, LUA_REGISTRYINDEX);
        }
    else
        {
        if(!GLMATH_COMPAT) return 0; /* already disabled */
        luaL_unref(L, LUA_REGISTRYINDEX, tovec2); tovec2 = LUA_NOREF;
        luaL_unref(L, LUA_REGISTRYINDEX, tovec4); tovec4 = LUA_NOREF;
        luaL_unref(L, LUA_REGISTRYINDEX, tomat2x3); tomat2x3 = LUA_NOREF;
        luaL_unref(L, LUA_REGISTRYINDEX, tobox2); tobox2 = LUA_NOREF;
        }
    return 0;
    }

/* vec_t ----------------------------------------------------------*/

int testvec(lua_State *L, int arg, vec_t *dst)
    {
    int isnum;
    int t = lua_type(L, arg);
    switch(t)
        {
        case LUA_TNONE:
        case LUA_TNIL:  return ERR_NOTPRESENT;
        case LUA_TTABLE: break;
        default: return ERR_TABLE;
        }
#define POP if(!isnum) { lua_pop(L, 1); return ERR_VALUE; } lua_pop(L, 1);
    lua_rawgeti(L, arg, 1); dst->x = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, arg, 2); dst->y = lua_tonumberx(L, -1, &isnum); POP
#undef POP
    return 0;
    }

int optvec(lua_State *L, int arg, vec_t *dst)
    {
    int ec = testvec(L, arg, dst);
    if(ec<0) return argerror(L, arg, ec);
    return ec;
    }

int checkvec(lua_State *L, int arg, vec_t *dst)
    {
    int ec = testvec(L, arg, dst);
    if(ec) return argerror(L, arg, ec);
    return ec;
    }

void pushvec(lua_State *L, const vec_t *val)
    {
    if(GLMATH_COMPAT) lua_rawgeti(L, LUA_REGISTRYINDEX, tovec2);
    lua_newtable(L);
    lua_pushnumber(L, val->x); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, val->y); lua_rawseti(L, -2, 2);
    if(GLMATH_COMPAT && lua_pcall(L,1,1,0)!=LUA_OK) { unexpected(L); return; }
    }

vec_t *checkveclist(lua_State *L, int arg, int *countp, int *err)
/* Check if the value at arg is a table of vecs and returns the corresponding
 * array of vec_t, stroing the size in *countp. The array is Malloc()'d and the
 * caller is in charge of Free()ing it.
 * If err=NULL, raises an error on failure, otherwise returns NULL and stores
 * the ERR_XXX code in *err.
 */
    {
    int count, i;
    vec_t *dst = NULL;
    *countp = 0;
#define ERR(ec) do { if(err) *err=(ec); else argerror(L, arg, (ec)); return NULL; } while(0)
    if(lua_isnoneornil(L, arg)) ERR(ERR_NOTPRESENT);
    if(lua_type(L, arg)!=LUA_TTABLE) ERR(ERR_TABLE);

    count = luaL_len(L, arg);
    if(count==0) ERR(ERR_EMPTY);
    dst = MallocNoErr(L, count*sizeof(vec_t));
    if(!dst) ERR(ERR_MEMORY);
    for(i=0; i<count; i++)
        {
        lua_rawgeti(L, arg, i+1);
        if(testvec(L, -1, &dst[i])!=0)
            { Free(L, dst); ERR(ERR_TYPE); }
        lua_pop(L, 1);
        }
#undef ERR
    *countp = count;
    if(err) *err=0;
    return dst;
    }

void pushveclist(lua_State *L, const vec_t *vecs , int count)
    {
    int i;
    lua_newtable(L);
    for(i=0; i<count; i++)
        {
        pushvec(L, &vecs[i]);
        lua_rawseti(L, -2, i+1);
        }
    }

/* mat_t ----------------------------------------------------------*/

/* In Lua: {{ a, c, tx },
 *          { b, d, ty },
 *          { 0, 0, 1  }}
 */

int testmat(lua_State *L, int arg, mat_t *dst)
    {
    int isnum;
    int t = lua_type(L, arg);
    switch(t)
        {
        case LUA_TNONE:
        case LUA_TNIL:  return ERR_NOTPRESENT;
        case LUA_TTABLE: break;
        default: return ERR_TABLE;
        }

#define POP if(!isnum) { lua_pop(L, 1); return ERR_VALUE; } lua_pop(L, 1);
    /* row 1 */
    lua_rawgeti(L, arg, 1); if(lua_type(L, -1)!=LUA_TTABLE) return argerror(L, arg, ERR_VALUE);
    lua_rawgeti(L, -1, 1); dst->a = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, -1, 2); dst->c = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, -1, 3); dst->tx = lua_tonumberx(L, -1, &isnum); POP
    lua_pop(L, 1);
    /* row 2 */
    lua_rawgeti(L, arg, 2); if(lua_type(L, -1)!=LUA_TTABLE) return argerror(L, arg, ERR_VALUE);
    lua_rawgeti(L, -1, 1); dst->b = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, -1, 2); dst->d = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, -1, 3); dst->ty = lua_tonumberx(L, -1, &isnum); POP
    lua_pop(L, 1);
    /* row 3, if any, is ignored */
#undef POP
    return 0;
    }

int optmat(lua_State *L, int arg, mat_t *dst)
    {
    int ec = testmat(L, arg, dst);
    if(ec<0) return argerror(L, arg, ec);
    return ec;
    }

int checkmat(lua_State *L, int arg, mat_t *dst)
    {
    int ec = testmat(L, arg, dst);
    if(ec) return argerror(L, arg, ec);
    return ec;
    }

void pushmat(lua_State *L, mat_t *val)
    {
    if(GLMATH_COMPAT) lua_rawgeti(L, LUA_REGISTRYINDEX, tomat2x3);
    lua_newtable(L);
    /* row 1 */
    lua_newtable(L);
    lua_pushnumber(L, val->a); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, val->c); lua_rawseti(L, -2, 2);
    lua_pushnumber(L, val->tx); lua_rawseti(L, -2, 3);
    lua_rawseti(L, -2, 1);
    /* row 2 */
    lua_newtable(L);
    lua_pushnumber(L, val->b); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, val->d); lua_rawseti(L, -2, 2);
    lua_pushnumber(L, val->ty); lua_rawseti(L, -2, 3);
    lua_rawseti(L, -2, 2);
    if(GLMATH_COMPAT && lua_pcall(L,1,1,0)!=LUA_OK) { unexpected(L); return; }
    }

/* bb_t ----------------------------------------------------------*/

/* Note:
 * Chipmunk's bbox order is {l, b, r, t}, ie {minx, miny, maxx, maxy}
 * MoonChipmunk's order is  {l, r, b, t}, ie {minx, maxx, miny, maxy}
 */

int testbb(lua_State *L, int arg, bb_t *dst)
    {
    int isnum;
    int t = lua_type(L, arg);
    switch(t)
        {
        case LUA_TNONE:
        case LUA_TNIL:  return ERR_NOTPRESENT;
        case LUA_TTABLE: break;
        default: return ERR_TABLE;
        }
#define POP if(!isnum) { lua_pop(L, 1); return ERR_VALUE; } lua_pop(L, 1);
    lua_rawgeti(L, arg, 1); dst->l = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, arg, 2); dst->r = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, arg, 3); dst->b = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, arg, 4); dst->t = lua_tonumberx(L, -1, &isnum); POP
#undef POP
    return 0;
    }

int optbb(lua_State *L, int arg, bb_t *dst)
    {
    int ec = testbb(L, arg, dst);
    if(ec<0) return argerror(L, arg, ec);
    return ec;
    }

int checkbb(lua_State *L, int arg, bb_t *dst)
    {
    int ec = testbb(L, arg, dst);
    if(ec) return argerror(L, arg, ec);
    return ec;
    }


void pushbb(lua_State *L, bb_t *val)
    {
    if(GLMATH_COMPAT) lua_rawgeti(L, LUA_REGISTRYINDEX, tobox2);
    lua_newtable(L);
    lua_pushnumber(L, val->l); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, val->r); lua_rawseti(L, -2, 2);
    lua_pushnumber(L, val->b); lua_rawseti(L, -2, 3);
    lua_pushnumber(L, val->t); lua_rawseti(L, -2, 4);
    if(GLMATH_COMPAT && lua_pcall(L,1,1,0)!=LUA_OK) { unexpected(L); return; }
    }

/* color_t --------------------------------------------------------*/

int testcolor(lua_State *L, int arg, color_t *dst)
    {
    int isnum;
    int t = lua_type(L, arg);
    switch(t)
        {
        case LUA_TNONE:
        case LUA_TNIL:  return ERR_NOTPRESENT;
        case LUA_TTABLE: break;
        default: return ERR_TABLE;
        }
#define POP if(!isnum) { lua_pop(L, 1); return ERR_VALUE; } lua_pop(L, 1);
    lua_rawgeti(L, arg, 1); dst->r = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, arg, 2); dst->g = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, arg, 3); dst->b = lua_tonumberx(L, -1, &isnum); POP
    lua_rawgeti(L, arg, 4); dst->a = lua_tonumberx(L, -1, &isnum); POP
#undef POP
    return 0;
    }

int optcolor(lua_State *L, int arg, color_t *dst)
    {
    int ec = testcolor(L, arg, dst);
    if(ec<0) return argerror(L, arg, ec);
    return ec;
    }

int checkcolor(lua_State *L, int arg, color_t *dst)
    {
    int ec = testcolor(L, arg, dst);
    if(ec) return argerror(L, arg, ec);
    return ec;
    }

void pushcolor(lua_State *L, color_t *val)
    {
    if(GLMATH_COMPAT) lua_rawgeti(L, LUA_REGISTRYINDEX, tovec4);
    lua_newtable(L);
    lua_pushnumber(L, val->r); lua_rawseti(L, -2, 1);
    lua_pushnumber(L, val->g); lua_rawseti(L, -2, 2);
    lua_pushnumber(L, val->b); lua_rawseti(L, -2, 3);
    lua_pushnumber(L, val->a); lua_rawseti(L, -2, 4);
    if(GLMATH_COMPAT && lua_pcall(L,1,1,0)!=LUA_OK) { unexpected(L); return; }
    }

/* cpPointQueryInfo ------------------------------------------------*/

void pushpointqueryinfo(lua_State *L, cpPointQueryInfo *val)
    {
    if(val->shape==NULL) { lua_pushnil(L); return; }
    if(userdata(val->shape)==NULL) unexpected(L); // unknown object
    lua_newtable(L);
    pushshape(L, val->shape); lua_setfield(L, -2, "shape");
    pushvec(L, &val->point); lua_setfield(L, -2, "point");
    lua_pushnumber(L, val->distance); lua_setfield(L, -2, "distance");
    pushvec(L, &val->gradient); lua_setfield(L, -2, "gradient");
    }

/* cpSegmentQueryInfo ----------------------------------------------*/

void pushsegmentqueryinfo(lua_State *L, cpSegmentQueryInfo *val)
    {
    if(val->shape==NULL) { lua_pushnil(L); return; }
    if(userdata(val->shape)==NULL) unexpected(L); // unknown object?
    lua_newtable(L);
    pushshape(L, val->shape); lua_setfield(L, -2, "shape");
    pushvec(L, &val->point); lua_setfield(L, -2, "point");
    pushvec(L, &val->normal); lua_setfield(L, -2, "normal");
    lua_pushnumber(L, val->alpha); lua_setfield(L, -2, "alpha");
    }

/* cpContactPointSet -----------------------------------------------*/

int checkcontactpointset(lua_State *L, int arg, cpContactPointSet *dst)
/* arg  : normal (vec)
 * arg+1: points ({contactpoint}, len <= CP_MAX_CONTACTS_PER_ARBITER)
 */
    {
    int isnum, i, count;
    int arg1 = arg+1;
    int top = lua_gettop(L);
    checkvec(L, arg, &dst->normal);
    if(lua_type(L, arg1)!=LUA_TTABLE) return argerror(L, arg1, ERR_TABLE);
    count = luaL_len(L, arg1);
    if(count > CP_MAX_CONTACTS_PER_ARBITER) return argerror(L, arg1, ERR_LENGTH);
    for(i=0; i<count; i++)
        {
        lua_rawgeti(L, arg1, i+1); /* points[i] */
          lua_getfield(L, -1, "distance");
            dst->points[i].distance = lua_tonumberx(L, -1, &isnum);
            if(!isnum) { lua_settop(L, top); return argerror(L, arg1, ERR_VALUE); }
          lua_pop(L, 1);
          lua_getfield(L, -1, "a");
            if(testvec(L, -1, &dst->points[i].pointA))
                { lua_settop(L, top); return  argerror(L, arg1, ERR_VALUE); }
          lua_pop(L, 1);
          lua_getfield(L, -1, "b");
            if(testvec(L, -1, &dst->points[i].pointB))
                { lua_settop(L, top); return  argerror(L, arg1, ERR_VALUE); }
          lua_pop(L, 1);
        lua_pop(L, 1); /* points[i] */
        }
    dst->count = count;
    lua_settop(L, top);
    return 0;
    }

int pushcontactpointset(lua_State *L, cpContactPointSet *val)
    {
    int i;
    if(val->count==0)
        { lua_pushnil(L); lua_pushnil(L); return 2; }
    pushvec(L, &val->normal);
    lua_newtable(L);
    for(i=0; i<val->count; i++)
        {
        lua_newtable(L);
        pushvec(L, &val->points[i].pointA); lua_setfield(L, -2, "a");
        pushvec(L, &val->points[i].pointB); lua_setfield(L, -2, "b");
        lua_pushnumber(L, val->points[i].distance); lua_setfield(L, -2, "distance");
        lua_rawseti(L, -2, i+1);
        }
    return 2;
    }

/* cpShapeFilter ---------------------------------------------------*/

int checkshapefilter(lua_State *L, int arg, cpShapeFilter *dst)
    {
    int isnum;
    int t = lua_type(L, arg);
    switch(t)
        {
        case LUA_TNONE:
        case LUA_TNIL:  return argerror(L, arg, ERR_NOTPRESENT);
        case LUA_TTABLE: break;
        default: return argerror(L, arg, ERR_TABLE);
        }
#define POP if(!isnum) { lua_pop(L, 1); return argerror(L, arg, ERR_VALUE); } lua_pop(L, 1);
    lua_getfield(L, arg, "group"); dst->group = (cpGroup)lua_tointegerx(L, -1, &isnum); POP
    lua_getfield(L, arg, "categories"); dst->categories = (cpBitmask)lua_tointegerx(L, -1, &isnum); POP
    lua_getfield(L, arg, "mask"); dst->mask = (cpBitmask)lua_tointegerx(L, -1, &isnum); POP
#undef POP
    return 0;
    }

void pushshapefilter(lua_State *L, cpShapeFilter *val)
    {
    lua_newtable(L);
    lua_pushinteger(L, val->group); lua_setfield(L, -2, "group");
    lua_pushinteger(L, val->categories); lua_setfield(L, -2, "categories");
    lua_pushinteger(L, val->mask); lua_setfield(L, -2, "mask");
    }


