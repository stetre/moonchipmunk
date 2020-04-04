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

static int freesegment(lua_State *L, ud_t *ud)
    {
    shape_t *shape = (shape_t*)ud->handle;
    if(!candestroyshape(shape, ud)) return 0;
    if(!freeuserdata(L, ud, "segment")) return 0;
    shapedestroy(L, (shape_t*)shape);
    return 0;
    }

static int newsegment(lua_State *L, shape_t *segment)
    {
    ud_t *ud;
    ud = newuserdata(L, segment, SEGMENT_MT, "segment");
    ud->parent_ud = NULL;
    ud->destructor = freesegment;
    return 1;
    }

static int Create(lua_State *L)
    {
    shape_t *segment;
    vec_t a, b;
    double radius;
    body_t *body = checkbody(L, 1, NULL);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    radius = luaL_checknumber(L, 4);
    segment = cpSegmentShapeNew(body, a, b, radius);
    return newsegment(L, segment);
    }

static int SetNeighbors(lua_State *L)
    {
    vec_t prev, next;
    shape_t *segment = checksegment(L, 1, NULL);
    checkvec(L, 2, &prev);
    checkvec(L, 3, &next);
    cpSegmentShapeSetNeighbors(segment, prev, next);
    return 0;
    }

#if 0
static int GetA(lua_State *L)
    {
    shape_t *segment = checksegment(L, 1, NULL);
    vec_t a = cpSegmentShapeGetA(segment);
    pushvec(L, &a);
    return 1;
    }

static int GetB(lua_State *L)
    {
    shape_t *segment = checksegment(L, 1, NULL);
    vec_t b = cpSegmentShapeGetB(segment);
    pushvec(L, &b);
    return 1;
    }
#endif

static int GetEndpoints(lua_State *L)
    {
    shape_t *segment = checksegment(L, 1, NULL);
    vec_t a = cpSegmentShapeGetA(segment);
    vec_t b = cpSegmentShapeGetB(segment);
    pushvec(L, &a);
    pushvec(L, &b);
    return 2;
    }

static int SetEndpoints(lua_State *L)
    {
    vec_t a, b;
    shape_t *segment = checksegment(L, 1, NULL);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    cpSegmentShapeSetEndpoints(segment, a, b);
    return 0;
    }

static int GetNormal(lua_State *L)
    {
    shape_t *segment = checksegment(L, 1, NULL);
    vec_t n = cpSegmentShapeGetNormal(segment);
    pushvec(L, &n);
    return 1;
    }

static int GetRadius(lua_State *L)
    {
    shape_t *segment = checksegment(L, 1, NULL);
    double radius = cpSegmentShapeGetRadius(segment);
    lua_pushnumber(L, radius);
    return 1;
    }

static int SetRadius(lua_State *L)
    {
    shape_t *segment = checksegment(L, 1, NULL);
    double radius = luaL_checknumber(L, 2);
    cpSegmentShapeSetRadius(segment, radius);
    return 0;
    }

DESTROY_FUNC(segment)

static const struct luaL_Reg Methods[] = 
    {
        { "free", Destroy },
        { "set_neighbors", SetNeighbors },
//      { "get_a", GetA },
//      { "get_b", GetB },
        { "get_normal", GetNormal },
        { "get_endpoints", GetEndpoints },
        { "set_endpoints", SetEndpoints }, /* chipmunk_unsafe.h */
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
        { "segment_shape_new", Create },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_segment(lua_State *L)
    {
    udata_define(L, SEGMENT_MT, Methods, MetaMethods);
    udata_inherit(L, SEGMENT_MT, SHAPE_MT);
    luaL_setfuncs(L, Functions, 0);
    }

