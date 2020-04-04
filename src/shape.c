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

int candestroyshape(shape_t *shape, ud_t *ud)
    {
    space_t *space;
    if(!IsValid(ud)) return 0; /* already destroyed */
    space = cpShapeGetSpace(shape);
    if(space && cpSpaceIsLocked(space)) return 0; /* leave it to post step callbacks */
    return 1;
    }

int shapedestroy(lua_State *L, shape_t *shape)
    {
    space_t *space = cpShapeGetSpace(shape);
    if(space)
        {
        if(cpSpaceIsLocked(space)) return failure(L, ERR_OPERATION);
        cpSpaceRemoveShape(space, shape);
        }
    cpShapeFree(shape);
    return 0;
    }

#define F(Func, func) /* void func(shape, double) */    \
static int Func(lua_State *L)                           \
    {                                                   \
    shape_t *shape = checkshape(L, 1, NULL);            \
    double val = luaL_checknumber(L, 2);                \
    func(shape, val);                                   \
    return 0;                                           \
    }
F(SetMass, cpShapeSetMass)
F(SetDensity, cpShapeSetDensity)
F(SetElasticity, cpShapeSetElasticity)
F(SetFriction, cpShapeSetFriction)
#undef F

#define F(Func, func) /* double func(shape) */          \
static int Func(lua_State *L)                           \
    {                                                   \
    shape_t *shape = checkshape(L, 1, NULL);            \
    double val = func(shape);                           \
    lua_pushnumber(L, val);                             \
    return 1;                                           \
    }
F(GetMass, cpShapeGetMass)
F(GetMoment, cpShapeGetMoment)
F(GetArea, cpShapeGetArea)
F(GetDensity, cpShapeGetDensity)
F(GetElasticity, cpShapeGetElasticity)
F(GetFriction, cpShapeGetFriction)
#undef F

static int GetSensor(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    lua_pushboolean(L, cpShapeGetSensor(shape));
    return 1;
    }

static int SetSensor(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    int sensor = checkboolean(L, 2);
    cpShapeSetSensor(shape, sensor);
    return 0;
    }

static int GetCenterOfGravity(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    vec_t pos = cpShapeGetCenterOfGravity(shape);
    pushvec(L, &pos);
    return 1;
    }

static int SetSurfaceVelocity(lua_State *L)
    {
    vec_t vel;
    shape_t *shape = checkshape(L, 1, NULL);
    checkvec(L, 2, &vel);
    cpShapeSetSurfaceVelocity(shape, vel);
    return 0;
    }

static int GetSurfaceVelocity(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    vec_t vel = cpShapeGetSurfaceVelocity(shape);
    pushvec(L, &vel);
    return 1;
    }

static int SetBody(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    body_t *body = checkbody(L, 2, NULL);
    cpShapeSetBody(shape, body);
    return 0;
    }

static int GetBody(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    body_t * body = cpShapeGetBody(shape);
    if(!body) lua_pushnil(L);
    else pushbody(L, body);
    return 1;
    }

static int GetSpace(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    space_t * space = cpShapeGetSpace(shape);
    if(!space) lua_pushnil(L);
    else pushspace(L, space);
    return 1;
    }

static int GetBB(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    bb_t box = cpShapeGetBB(shape);
    pushbb(L, &box);
    return 1;
    }

static int CacheBB(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    bb_t box = cpShapeCacheBB(shape);
    pushbb(L, &box);
    return 1;
    }

static int Update(lua_State *L)
    {
    bb_t box;
    mat_t transform;
    shape_t *shape = checkshape(L, 1, NULL);
    checkmat(L, 2, &transform);
    box = cpShapeUpdate(shape, transform);
    pushbb(L, &box);
    return 1;
    }

static int SetCollisionType(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    cpCollisionType val = luaL_checkinteger(L, 2);
    cpShapeSetCollisionType(shape, val);
    return 0;
    }

static int GetCollisionType(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    cpCollisionType val = cpShapeGetCollisionType(shape);
    lua_pushinteger(L, val);
    return 1;
    }

static int PointQuery(lua_State *L)
    {
    vec_t p;
    cpPointQueryInfo out;
    double res;
    shape_t *shape = checkshape(L, 1, NULL);
    checkvec(L, 2, &p);
    res = cpShapePointQuery(shape, p, &out);
    (void)res; //lua_pushnumber(L, res); -- already contained in pointqueryinfo
    pushpointqueryinfo(L, &out);
    return 1;
    }

static int SegmentQuery(lua_State *L)
    {
    vec_t a, b;
    double radius;
    cpSegmentQueryInfo info;
    shape_t *shape = checkshape(L, 1, NULL);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    radius = luaL_checknumber(L, 4);
    if(cpShapeSegmentQuery(shape, a, b, radius, &info))
        pushsegmentqueryinfo(L, &info);
    else
        lua_pushnil(L);
    return 1;
    }

static int Collide(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    shape_t *other = checkshape(L, 2, NULL);
    cpContactPointSet set = cpShapesCollide(shape, other);
    return pushcontactpointset(L, &set);
    }

static int SetFilter(lua_State *L)
    {
    cpShapeFilter filter;
    shape_t *shape = checkshape(L, 1, NULL);
    checkshapefilter(L, 2, &filter);
    cpShapeSetFilter(shape, filter);
    return 0;
    }

static int GetFilter(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    cpShapeFilter filter = cpShapeGetFilter(shape);
    pushshapefilter(L, &filter);
    return 1;
    }

static int GetHashid(lua_State *L)
    {
    shape_t *shape = checkshape(L, 1, NULL);
    lua_pushinteger(L, shape->hashid); /* need chipmunk_private.h for this */
    return 1;
    }

static int ShapeFilterNew(lua_State *L)
    {
    cpGroup group = luaL_checkinteger(L, 1);
    cpBitmask categories = luaL_checkinteger(L, 2);
    cpBitmask mask = luaL_checkinteger(L, 3);
    cpShapeFilter filter = cpShapeFilterNew(group, categories, mask);
    pushshapefilter(L, &filter);
    return 1;
    }

static int ShapeFilterAll(lua_State *L)
    {
    cpShapeFilter filter = CP_SHAPE_FILTER_ALL;
    pushshapefilter(L, &filter);
    return 1;
    }

static int ShapeFilterNone(lua_State *L)
    {
    cpShapeFilter filter = CP_SHAPE_FILTER_NONE;
    pushshapefilter(L, &filter);
    return 1;
    }

RAW_FUNC(shape)
PARENT_FUNC(shape)
DESTROY_FUNC(shape)

static const struct luaL_Reg Methods[] = 
    {
        { "raw", Raw },
        { "parent", Parent },
        { "free", Destroy },
        { "set_mass", SetMass },
        { "set_density", SetDensity },
        { "set_elasticity", SetElasticity },
        { "set_friction", SetFriction },
        { "get_mass", GetMass },
        { "get_moment", GetMoment },
        { "get_area", GetArea },
        { "get_density", GetDensity },
        { "get_elasticity", GetElasticity },
        { "get_friction", GetFriction },
        { "get_sensor", GetSensor },
        { "set_sensor", SetSensor },
        { "get_center_of_gravity", GetCenterOfGravity },
        { "set_surface_velocity", SetSurfaceVelocity },
        { "get_surface_velocity", GetSurfaceVelocity },
        { "set_body", SetBody },
        { "get_body", GetBody },
        { "get_space", GetSpace },
        { "get_bb", GetBB },
        { "cache_bb", CacheBB },
        { "update", Update },
        { "set_collision_type", SetCollisionType },
        { "get_collision_type", GetCollisionType },
        { "point_query", PointQuery },
        { "segment_query", SegmentQuery },
        { "collide", Collide },
        { "set_filter", SetFilter },
        { "get_filter", GetFilter },
        { "get_hashid", GetHashid },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { "shapes_collide", Collide },
        { "shape_filter_new", ShapeFilterNew },
        { "shape_filter_all", ShapeFilterAll },
        { "shape_filter_none", ShapeFilterNone },
        { NULL, NULL } /* sentinel */
    };


void moonchipmunk_open_shape(lua_State *L)
    {
    udata_define(L, SHAPE_MT, Methods, MetaMethods);
    luaL_setfuncs(L, Functions, 0);
    }

#if 0
//cpDataPointer cpShapeGetUserData(const shape_t *shape);
//void cpShapeSetUserData(shape_t *shape, cpDataPointer userData);
#endif
