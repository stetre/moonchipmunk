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

static int freepoly(lua_State *L, ud_t *ud)
    {
    shape_t *shape = (shape_t*)ud->handle;
    if(!candestroyshape(shape, ud)) return 0;
    if(!freeuserdata(L, ud, "poly")) return 0;
    shapedestroy(L, (shape_t*)shape);
    return 0;
    }

static int newpoly(lua_State *L, shape_t *poly)
    {
    ud_t *ud;
    ud = newuserdata(L, poly, POLY_MT, "poly");
    ud->parent_ud = NULL;
    ud->destructor = freepoly;
    return 1;
    }

static int PolyShapeNew(lua_State *L)
    {
    int count, raw=0;
    double radius;
    mat_t transform;
    vec_t *verts;
    shape_t *poly;
    body_t *body = checkbody(L, 1, NULL);
    if(lua_isnoneornil(L, 4)) raw=1; else checkmat(L, 4, &transform);
    radius = luaL_checknumber(L, 3);
    verts = checkveclist(L, 2, &count, NULL);
    poly = raw ?  cpPolyShapeNewRaw(body, count, verts, radius) :
        cpPolyShapeNew(body, count, verts, transform, radius);
    Free(L, verts);
    return newpoly(L, poly);
    }

static int BoxShapeNew(lua_State *L)
    {
    shape_t *poly;
    bb_t box;
    double width, height, radius;
    body_t *body = checkbody(L, 1, NULL);
    if(lua_isnumber(L, 2))
        {
        width = luaL_checknumber(L, 2);
        height = luaL_checknumber(L, 3);
        radius = luaL_checknumber(L, 4);
        poly = cpBoxShapeNew(body, width, height, radius);
        }
    else
        {
        checkbb(L, 2, &box);
        radius = luaL_checknumber(L, 3);
        poly = cpBoxShapeNew2(body, box, radius);
        }
    return newpoly(L, poly);
    }

static int GetCount(lua_State *L)
    {
    shape_t *poly = checkpoly(L, 1, NULL);
    int count = cpPolyShapeGetCount(poly);
    lua_pushnumber(L, count);
    return 1;
    }

static int GetVerts(lua_State *L)
    {
    int i;
    vec_t vert;
    shape_t *poly = checkpoly(L, 1, NULL);
    int count = cpPolyShapeGetCount(poly);
    lua_newtable(L);
    for(i=0; i<count; i++)
        {
        vert = cpPolyShapeGetVert(poly, i);
        pushvec(L, &vert);
        lua_rawseti(L, -2, i+1);
        }
    return 1;
    }

static int SetVerts(lua_State *L)
    {
    mat_t transform;
    int count, raw=0;
    vec_t *verts;
    shape_t *poly = checkpoly(L, 1, NULL);
    if(lua_isnoneornil(L, 3)) raw=1; else checkmat(L, 3, &transform);
    verts = checkveclist(L, 2, &count, NULL);
    if(raw)
        cpPolyShapeSetVertsRaw(poly, count, verts);
    else
        cpPolyShapeSetVerts(poly, count, verts, transform);
    Free(L, verts);
    return 0;
    }


static int GetRadius(lua_State *L)
    {
    shape_t *poly = checkpoly(L, 1, NULL);
    double radius = cpPolyShapeGetRadius(poly);
    lua_pushnumber(L, radius);
    return 1;
    }

static int SetRadius(lua_State *L)
    {
    shape_t *poly = checkpoly(L, 1, NULL);
    double radius = luaL_checknumber(L, 2);
    cpPolyShapeSetRadius(poly, radius);
    return 0;
    }

DESTROY_FUNC(poly)

static const struct luaL_Reg Methods[] = 
    {
        { "free", Destroy },
        { "get_count", GetCount },
        { "get_verts", GetVerts },
        { "set_verts", SetVerts }, /* chipmunk_unsafe.h */
        { "get_radius", GetRadius },
        { "set_radius", SetRadius }, /* chipmunk_unsafe.h */
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { "poly_shape_new", PolyShapeNew },
        { "box_shape_new", BoxShapeNew },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_poly(lua_State *L)
    {
    udata_define(L, POLY_MT, Methods, MetaMethods);
    udata_inherit(L, POLY_MT, SHAPE_MT);
    luaL_setfuncs(L, Functions, 0);
    }

