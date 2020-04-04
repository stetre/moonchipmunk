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

static int freecircle(lua_State *L, ud_t *ud)
    {
    shape_t *shape = (shape_t*)ud->handle;
    if(!candestroyshape(shape, ud)) return 0;
    if(!freeuserdata(L, ud, "circle")) return 0;
    shapedestroy(L, (shape_t*)shape);
    return 0;
    }

static int newcircle(lua_State *L, shape_t *circle)
    {
    ud_t *ud;
    ud = newuserdata(L, circle, CIRCLE_MT, "circle");
    ud->parent_ud = NULL;
    ud->destructor = freecircle;
    return 1;
    }

static int Create(lua_State *L)
    {
    shape_t *circle;
    vec_t offset;
    body_t *body = checkbody(L, 1, NULL);
    double radius = luaL_checknumber(L, 2);
    offset.x = offset.y = 0.0;
    optvec(L, 3, &offset);
    circle = cpCircleShapeNew(body, radius, offset);
    return newcircle(L, circle);
    }

static int GetOffset(lua_State *L)
    {
    shape_t *circle = checkcircle(L, 1, NULL);
    vec_t offset = cpCircleShapeGetOffset(circle);
    pushvec(L, &offset);
    return 1;
    }

static int SetOffset(lua_State *L)
    {
    vec_t offset;
    shape_t *circle = checkcircle(L, 1, NULL);
    checkvec(L, 2, &offset);
    cpCircleShapeSetOffset(circle, offset);
    return 0;
    }

static int GetRadius(lua_State *L)
    {
    shape_t *circle = checkcircle(L, 1, NULL);
    double radius = cpCircleShapeGetRadius(circle);
    lua_pushnumber(L, radius);
    return 1;
    }

static int SetRadius(lua_State *L)
    {
    shape_t *circle = checkcircle(L, 1, NULL);
    double radius = luaL_checknumber(L, 2);
    cpCircleShapeSetRadius(circle, radius);
    return 0;
    }


DESTROY_FUNC(circle)

static const struct luaL_Reg Methods[] = 
    {
        { "free", Destroy },
        { "get_offset", GetOffset },
        { "get_radius", GetRadius },
        { "set_offset", SetOffset }, /* chipmunk_unsafe.h */
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
        { "circle_shape_new", Create },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_circle(lua_State *L)
    {
    udata_define(L, CIRCLE_MT, Methods, MetaMethods);
    udata_inherit(L, CIRCLE_MT, SHAPE_MT);
    luaL_setfuncs(L, Functions, 0);
    }

