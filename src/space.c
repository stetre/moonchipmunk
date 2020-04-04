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

/* references for debug draw functions (index in info->ref[]) */
#define REF_drawCircle          0
#define REF_drawSegment         1
#define REF_drawFatSegment      2
#define REF_drawPolygon         3
#define REF_drawDot             4
#define REF_colorForShape       5
#define NREFS                   6

typedef struct info_t {
    int ref[NREFS];
    cpSpaceDebugDrawOptions options;
} info_t;

static void clearinfo(lua_State *L, info_t *info)
    {
    for(int i=0; i <NREFS; i++)
        { if(info->ref[i]!=LUA_NOREF) luaL_unref(L, LUA_REGISTRYINDEX, info->ref[i]); }
    memset(info, 0, sizeof(info_t));
    }

static void removebody(space_t *space, void *key, void *data)
    { cpSpaceRemoveBody(space, (body_t*)key); (void)data; }
static void postremovebody(body_t *body, void *data)
    { cpSpaceAddPostStepCallback((space_t*)data, removebody, body, NULL); }

static void removeshape(space_t *space, void *key, void *data)
    { cpSpaceRemoveShape(space, (shape_t*)key); (void)data; }
static void postremoveshape(shape_t *shape, void *data)
    { cpSpaceAddPostStepCallback((space_t*)data, removeshape, shape, NULL);  }

static void removeconstraint(space_t *space, void *key, void *data)
    { cpSpaceRemoveConstraint(space, (constraint_t*)key); (void)data; }
static void postremoveconstraint(constraint_t *constraint, void *data)
    { cpSpaceAddPostStepCallback((space_t*)data, removeconstraint, constraint, NULL);  }

static int freespace(lua_State *L, ud_t *ud)
    {
    ud_t *static_body_ud;
    space_t *space = (space_t*)ud->handle;
    body_t* static_body = ud->static_body;
    int hasty = IsHasty(ud);
    info_t* info = (info_t*)ud->info;
    ud->info = NULL;
    freechildren(L, COLLISION_HANDLER_MT, ud);
    if(!freeuserdata(L, ud, "space")) return 0;
    clearinfo(L, info);
    Free(L, info);
    static_body_ud = userdata(static_body); 
    if(static_body_ud) freebody(L, static_body_ud);
    /* remove all shapes, constraints and bodies */
    cpSpaceEachConstraint(space, postremoveconstraint, space);
    cpSpaceEachShape(space, postremoveshape, space);
    cpSpaceEachBody(space, postremovebody, space);
    hasty ? cpHastySpaceFree(space) : cpSpaceFree(space);
    return 0;
    }

static int newspace(lua_State *L, space_t *space, int hasty)
    {
    ud_t *ud;
    info_t *info = Malloc(L, sizeof(info_t));
    ud = newuserdata(L, space, SPACE_MT, "space");
    ud->parent_ud = NULL;
    ud->destructor = freespace;
    ud->static_body = NULL;
    ud->info = info;
    if(hasty) MarkHasty(ud);
    return 1;
    }

static int Create(lua_State *L)
    {
    space_t *space = cpSpaceNew();
    return newspace(L, space, 0);
    }

static int CreateHasty(lua_State *L)
    {
    space_t *space = cpHastySpaceNew();
    return newspace(L, space, 1);
    }

static int SetIterations(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    int iterations = luaL_checkinteger(L, 2);
    cpSpaceSetIterations(space, iterations);
    return 0;
    }

static int GetIterations(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    int iterations =  cpSpaceGetIterations(space);
    lua_pushinteger(L, iterations);
    return 1;
    }

static int SetGravity(lua_State *L)
    {
    vec_t gravity;
    space_t *space = checkspace(L, 1, NULL);
    checkvec(L, 2, &gravity);
    cpSpaceSetGravity(space, gravity);
    return 0;
    }

static int GetGravity(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    vec_t gravity = cpSpaceGetGravity(space);
    pushvec(L, &gravity);
    return 1;
    }

#define F(Func, func) /* void func(space, double) */    \
static int Func(lua_State *L)                           \
    {                                                   \
    space_t *space = checkspace(L, 1, NULL);            \
    double val = luaL_checknumber(L, 2);                \
    func(space, val);                                   \
    return 0;                                           \
    }
F(SetDamping, cpSpaceSetDamping)
F(SetIdleSpeedThreshold, cpSpaceSetIdleSpeedThreshold)
F(SetSleepTimeThreshold, cpSpaceSetSleepTimeThreshold)
F(SetCollisionSlop, cpSpaceSetCollisionSlop)
F(SetCollisionBias, cpSpaceSetCollisionBias)
#undef F

static int Step(lua_State *L)
    {
    int i;
    ud_t *ud;
    space_t *space = checkspace(L, 1, &ud);
    double dt = luaL_checknumber(L, 2);
    int n = luaL_optinteger(L, 3, 1);
    if(n==1)
        IsHasty(ud) ? cpHastySpaceStep(space, dt) : cpSpaceStep(space, dt);
    else
        {
        if(IsHasty(ud))
            for(i=0; i<n; i++) cpHastySpaceStep(space, dt);
        else
            for(i=0; i<n; i++) cpSpaceStep(space, dt);
        }
    return 0;
    }

#define F(Func, func) /* double func(space) */          \
static int Func(lua_State *L)                           \
    {                                                   \
    space_t *space = checkspace(L, 1, NULL);            \
    double val = func(space);                           \
    lua_pushnumber(L, val);                             \
    return 1;                                           \
    }
F(GetDamping, cpSpaceGetDamping)
F(GetIdleSpeedThreshold, cpSpaceGetIdleSpeedThreshold)
F(GetSleepTimeThreshold, cpSpaceGetSleepTimeThreshold)
F(GetCollisionSlop, cpSpaceGetCollisionSlop)
F(GetCollisionBias, cpSpaceGetCollisionBias)
F(GetCurrentTimeStep, cpSpaceGetCurrentTimeStep)
#undef F

static int SetCollisionPersistence(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    cpTimestamp timestamp = luaL_checkinteger(L, 2);
    cpSpaceSetCollisionPersistence(space, timestamp);
    return 0;
    }

static int GetCollisionPersistence(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    cpTimestamp timestamp = cpSpaceGetCollisionPersistence(space);
    lua_pushinteger(L, timestamp);
    return 1;
    }

#define F(Func, func) /* bool func(space) */            \
static int Func(lua_State *L)                           \
    {                                                   \
    space_t *space = checkspace(L, 1, NULL);            \
    int val = func(space);                              \
    lua_pushboolean(L, val);                            \
    return 1;                                           \
    }
F(IsLocked, cpSpaceIsLocked)
#undef F

static int GetStaticBody(lua_State *L)
    {
    ud_t *space_ud;
    space_t *space = checkspace(L, 1, &space_ud);
    body_t* body = cpSpaceGetStaticBody(space);
    ud_t *ud = userdata(body);
    if(ud)
        pushbody(L, body);
    else /* create userdata for borrowed body */
        {
        newbody(L, body, 1);
        space_ud->static_body = body;
        }
    return 1;
    }

#define F(Func, func, what)                     \
static int Func(lua_State *L)                   \
    {                                           \
    space_t *space = checkspace(L, 1, NULL);    \
    what##_t *what = check##what(L, 2, NULL);   \
    what = func(space, what);                   \
    push##what(L, what);                        \
    return 1;                                   \
    }
F(AddShape, cpSpaceAddShape, shape)
F(AddBody, cpSpaceAddBody, body)
F(AddConstraint, cpSpaceAddConstraint, constraint)
#undef F

#define F(Func, func, what)                     \
static int Func(lua_State *L)                   \
    {                                           \
    space_t *space = checkspace(L, 1, NULL);    \
    what##_t *what = check##what(L, 2, NULL);   \
    func(space, what);                          \
    return 0;                                   \
    }
F(RemoveShape, cpSpaceRemoveShape, shape)
F(RemoveBody, cpSpaceRemoveBody, body)
F(RemoveConstraint, cpSpaceRemoveConstraint, constraint)
#undef F

#define F(Func, func, what)                     \
static int Func(lua_State *L)                   \
    {                                           \
    space_t *space = checkspace(L, 1, NULL);    \
    what##_t *what = check##what(L, 2, NULL);   \
    lua_pushboolean(L, func(space, what));      \
    return 1;                                   \
    }
F(ContainsShape, cpSpaceContainsShape, shape)
F(ContainsBody, cpSpaceContainsBody, body)
F(ContainsConstraint, cpSpaceContainsConstraint, constraint)
#undef F

    
static int ReindexStatic(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    cpSpaceReindexStatic(space);
    return 0;
    }

static int ReindexShape(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    shape_t *shape = checkshape(L, 2, NULL);
    cpSpaceReindexShape(space, shape);
    return 0;
    }

static int ReindexShapesForBody(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    body_t *body = checkbody(L, 2, NULL);
    cpSpaceReindexShapesForBody(space, body);
    return 0;
    }

static int UseSpatialHash(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    double dim = luaL_checknumber(L, 2);
    int count = luaL_checkinteger(L, 3);
    cpSpaceUseSpatialHash(space, dim, count);
    return 0;
    }


#define F(Func, What, what)                                                 \
static void IteratorFunc##What(what##_t *what, void *data /*=space*/)       \
    {                                                                       \
    lua_State *L = moonchipmunk_L;                                          \
    int top = lua_gettop(L);                                                \
    lua_pushvalue(L, 2);    /* the function */                              \
    pushspace(L, (space_t*)data);                                           \
    push##what(L, what);                                                    \
    if(lua_pcall(L, 2, 0, 0) != LUA_OK)                                     \
        { lua_error(L); return; }                                           \
    lua_settop(L, top);                                                     \
    }                                                                       \
static int Func(lua_State *L)                                               \
    {                                                                       \
    space_t *space = checkspace(L, 1, NULL);                                \
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);          \
    cpSpaceEach##What(space, IteratorFunc##What, /*data=*/space);           \
    return 0;                                                               \
    }
F(EachBody, Body, body)
F(EachConstraint, Constraint, constraint)
F(EachShape, Shape, shape)
#undef F

static int AddDefaultCollisionHandler(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    cpCollisionHandler *handler = cpSpaceAddDefaultCollisionHandler(space);
    newcollision_handler(L, handler, space);
    return 1;
    }

static int AddCollisionHandler(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    cpCollisionType a = luaL_checkinteger(L, 2);
    cpCollisionType b = luaL_checkinteger(L, 3);
    cpCollisionHandler *handler = cpSpaceAddCollisionHandler(space, a, b);
    newcollision_handler(L, handler, space);
    return 1;
    }

static int AddWildcardHandler(lua_State *L)
    {
    space_t *space = checkspace(L, 1, NULL);
    cpCollisionType type = luaL_checkinteger(L, 2);
    cpCollisionHandler *handler = cpSpaceAddWildcardHandler(space, type);
    newcollision_handler(L, handler, space);
    return 1;
    }


// Post-Step Callbacks --------------------------------------------------------
static void PostStepFunc(space_t *space, void *key, void *data)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    intptr_t ref = (intptr_t)key;
    (void)data;
    lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
    pushspace(L, space);
    rc = lua_pcall(L, 1, 0, 0);
    luaL_unref(L, LUA_REGISTRYINDEX, ref);
    if(rc!=LUA_OK) lua_error(L);
    }

static int AddPostStepCallback(lua_State *L)
    {
    intptr_t ref;
    space_t *space = checkspace(L, 1, NULL);
    if(!lua_isfunction(L, 2))
        return argerror(L, 2, ERR_FUNCTION);
    lua_pushvalue(L, 2);
    ref = luaL_ref(L, LUA_REGISTRYINDEX);
    if(!cpSpaceAddPostStepCallback(space, PostStepFunc, (void*)ref, NULL))
        return unexpected(L);
    return 0;
    }

static int SegmentQueryFirst(lua_State *L)
    {
    vec_t start, end;
    double radius;
    cpShapeFilter filter;
    cpSegmentQueryInfo out;
    space_t *space = checkspace(L, 1, NULL);
    checkvec(L, 2, &start);
    checkvec(L, 3, &end);
    radius = luaL_checknumber(L, 4);
    checkshapefilter(L, 5, &filter);
    if(cpSpaceSegmentQueryFirst(space, start, end, radius, filter, &out)!=NULL)
        pushsegmentqueryinfo(L, &out);
    else
        lua_pushnil(L);
    return 1;
    }

static int PointQueryNearest(lua_State *L)
    {
    vec_t point;
    double maxdist;
    cpShapeFilter filter;
    cpPointQueryInfo out;
    space_t *space = checkspace(L, 1, NULL);
    checkvec(L, 2, &point);
    maxdist = luaL_checknumber(L, 3);
    checkshapefilter(L, 4, &filter);
    if(cpSpacePointQueryNearest(space, point, maxdist, filter, &out)!=NULL)
        pushpointqueryinfo(L, &out);
    else
        lua_pushnil(L);
    return 1;
    }

static void PointQueryFunc(shape_t *shape, vec_t point, double distance, vec_t gradient, void *data)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    space_t *space = (space_t*)data;
    ud_t *ud = userdata(space);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    pushspace(L, space);
    pushshape(L, shape);
    pushvec(L, &point);
    lua_pushnumber(L, distance);
    pushvec(L, &gradient);
    rc = lua_pcall(L, 5, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    }

static int PointQuery(lua_State *L)
    {
    ud_t *ud;
    vec_t point;
    double maxdist;
    cpShapeFilter filter;
    space_t *space = checkspace(L, 1, &ud);
    checkvec(L, 2, &point);
    maxdist = luaL_checknumber(L, 3);
    checkshapefilter(L, 4, &filter);
    if(!lua_isfunction(L, 5)) return argerror(L, 5, ERR_FUNCTION);
    lua_pushvalue(L, 5);
    ud->ref1 = luaL_ref(L, LUA_REGISTRYINDEX);
    cpSpacePointQuery(space, point, maxdist, filter, PointQueryFunc, space);
    luaL_unref(L, LUA_REGISTRYINDEX, ud->ref1);
    return 0;
    }

static void SegmentQueryFunc(shape_t *shape, vec_t point, vec_t normal, double alpha, void *data)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    space_t *space = (space_t*)data;
    ud_t *ud = userdata(space);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    pushspace(L, space);
    pushshape(L, shape);
    pushvec(L, &point);
    pushvec(L, &normal);
    lua_pushnumber(L, alpha);
    rc = lua_pcall(L, 5, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    }

static int SegmentQuery(lua_State *L)
    {
    ud_t *ud;
    vec_t start, end;
    double radius;
    cpShapeFilter filter;
    space_t *space = checkspace(L, 1, &ud);
    checkvec(L, 2, &start);
    checkvec(L, 3, &end);
    radius = luaL_checknumber(L, 4);
    checkshapefilter(L, 5, &filter);
    if(!lua_isfunction(L, 6)) return argerror(L, 6, ERR_FUNCTION);
    lua_pushvalue(L, 6);
    ud->ref1 = luaL_ref(L, LUA_REGISTRYINDEX);
    cpSpaceSegmentQuery(space, start, end, radius, filter, SegmentQueryFunc, space);
    luaL_unref(L, LUA_REGISTRYINDEX, ud->ref1);
    return 0;
    }


static void BBQueryFunc(shape_t *shape, void *data)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    space_t *space = (space_t*)data;
    ud_t *ud = userdata(space);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    pushspace(L, space);
    pushshape(L, shape);
    rc = lua_pcall(L, 2, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    }
static int BBQuery(lua_State *L)
    {
    ud_t *ud;
    bb_t bb;
    cpShapeFilter filter;
    space_t *space = checkspace(L, 1, &ud);
    checkbb(L, 2, &bb);
    checkshapefilter(L, 3, &filter);
    if(!lua_isfunction(L, 4)) return argerror(L, 4, ERR_FUNCTION);
    lua_pushvalue(L, 4);
    ud->ref1 = luaL_ref(L, LUA_REGISTRYINDEX);
    cpSpaceBBQuery(space, bb, filter, BBQueryFunc, space);
    luaL_unref(L, LUA_REGISTRYINDEX, ud->ref1);
    return 0;
    }

static void ShapeQueryFunc(shape_t *shape, cpContactPointSet *points, void *data)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    space_t *space = (space_t*)data;
    ud_t *ud = userdata(space);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    pushspace(L, space);
    pushshape(L, shape);
    pushcontactpointset(L, points); // normal, {points}
    rc = lua_pcall(L, 4, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    }
static int ShapeQuery(lua_State *L)
    {
    ud_t *ud;
    bb_t bb;
    cpShapeFilter filter;
    space_t *space = checkspace(L, 1, &ud);
    shape_t *shape = checkshape(L, 2, NULL);
    if(!lua_isfunction(L, 3)) return argerror(L, 3, ERR_FUNCTION);
    lua_pushvalue(L, 3);
    ud->ref1 = luaL_ref(L, LUA_REGISTRYINDEX);
    cpSpaceBBQuery(space, bb, filter, BBQueryFunc, space);
    lua_pushboolean(L, cpSpaceShapeQuery(space, shape, ShapeQueryFunc, space));
    luaL_unref(L, LUA_REGISTRYINDEX, ud->ref1);
    return 1;
    }

static int SetThreads(lua_State *L)
    {
    ud_t *ud;
    unsigned long threads;
    space_t *space = checkspace(L, 1, &ud);
    if(!IsHasty(ud))
        return argerror(L, 1, ERR_OPERATION);
    threads = luaL_checknumber(L, 2);
    cpHastySpaceSetThreads(space, threads);
    return 0;
    }

static int GetThreads(lua_State *L)
    {
    ud_t *ud;
    unsigned long threads;
    space_t *space = checkspace(L, 1, &ud);
    if(!IsHasty(ud))
        return argerror(L, 1, ERR_OPERATION);
    threads = cpHastySpaceGetThreads(space);
    lua_pushinteger(L, threads);
    return 1;
    }


#define L moonchipmunk_L
#define info ((info_t*)(data))
static void DrawCircle(vec_t pos, double angle, double radius, color_t outlineColor, color_t fillColor, void* data)
    {
    int rc;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, info->ref[REF_drawCircle]);
    pushvec(L, &pos);
    lua_pushnumber(L, angle);
    lua_pushnumber(L, radius);
    pushcolor(L, &outlineColor); 
    pushcolor(L, &fillColor); 
    rc = lua_pcall(L, 5, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    lua_settop(L, top);
    }

static void DrawSegment(vec_t a, vec_t b, color_t color, void* data)
    {
    int rc;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, info->ref[REF_drawSegment]);
    pushvec(L, &a);
    pushvec(L, &b);
    pushcolor(L, &color); 
    rc = lua_pcall(L, 3, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    lua_settop(L, top);
    }

static void DrawFatSegment(vec_t a, vec_t b, double radius, color_t outlineColor, color_t fillColor, void* data)
    {
    int rc;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, info->ref[REF_drawFatSegment]);
    pushvec(L, &a);
    pushvec(L, &b);
    lua_pushnumber(L, radius);
    pushcolor(L, &outlineColor); 
    pushcolor(L, &fillColor); 
    rc = lua_pcall(L, 5, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    lua_settop(L, top);
    }

static void DrawPolygon(int count, const vec_t *verts, double radius, color_t outlineColor, color_t fillColor, void* data)
    {
    int rc;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, info->ref[REF_drawPolygon]);
    pushveclist(L, verts, count);
    lua_pushnumber(L, radius);
    pushcolor(L, &outlineColor); 
    pushcolor(L, &fillColor); 
    rc = lua_pcall(L, 4, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    lua_settop(L, top);
    }

static void DrawDot(double size, vec_t pos, color_t color, void* data)
    {
    int rc;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, info->ref[REF_drawDot]);
    lua_pushnumber(L, size);
    pushvec(L, &pos);
    pushcolor(L, &color); 
    rc = lua_pcall(L, 3, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    lua_settop(L, top);
    }

static color_t DrawColorForShape(shape_t *shape, void* data)
    {
    color_t res;
    int rc;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, info->ref[REF_colorForShape]);
    pushshape(L, shape);
    rc = lua_pcall(L, 1, 1, 0);
    if(rc!=LUA_OK) lua_error(L);
    checkcolor(L, -1, &res);
    lua_settop(L, top);
    return res;
    }
#undef L
#undef info

static int SetDebugDrawOptions(lua_State *L)
    {
    ud_t *ud;
    info_t* info;
    (void)checkspace(L, 1, &ud);
    info = (info_t*)ud->info;
    clearinfo(L, info);
    for(int i=0; i<NREFS; i++)
        if(!lua_isfunction(L, 2+i)) return argerror(L, 2+i, ERR_FUNCTION);
    info->options.flags = checkflags(L, 8); // debugdrawflags
    checkcolor(L, 9, &(info->options.shapeOutlineColor));
    checkcolor(L, 10, &(info->options.constraintColor));
    checkcolor(L, 11, &(info->options.collisionPointColor));
    lua_pushvalue(L, 2); info->ref[REF_drawCircle] = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pushvalue(L, 3); info->ref[REF_drawSegment] = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pushvalue(L, 4); info->ref[REF_drawFatSegment] = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pushvalue(L, 5); info->ref[REF_drawPolygon] = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pushvalue(L, 6); info->ref[REF_drawDot] = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pushvalue(L, 7); info->ref[REF_colorForShape] = luaL_ref(L, LUA_REGISTRYINDEX);
    info->options.drawCircle = DrawCircle;
    info->options.drawSegment = DrawSegment;
    info->options.drawFatSegment = DrawFatSegment;
    info->options.drawPolygon = DrawPolygon;
    info->options.drawDot = DrawDot;
    info->options.colorForShape = DrawColorForShape;
    info->options.data = info;
    return 0;
    }

static int DebugDraw(lua_State *L)
    {
    ud_t *ud;
    space_t *space = checkspace(L, 1, &ud);
    info_t *info = (info_t*)ud->info;
    if(info->ref[0]==LUA_NOREF)
        return luaL_error(L, "debug draw options are not set");
    cpSpaceDebugDraw(space, &(info->options));
    return 0;
    }

RAW_FUNC(space)
PARENT_FUNC(space)
DESTROY_FUNC(space)

static const struct luaL_Reg Methods[] = 
    {
        { "raw", Raw },
        { "parent", Parent },
        { "free", Destroy },
        { "set_iterations", SetIterations },
        { "get_iterations", GetIterations },
        { "set_gravity", SetGravity },
        { "get_gravity", GetGravity },
        { "set_damping", SetDamping },
        { "get_damping", GetDamping },
        { "set_idle_speed_threshold", SetIdleSpeedThreshold },
        { "get_idle_speed_threshold", GetIdleSpeedThreshold },
        { "set_sleep_time_threshold", SetSleepTimeThreshold },
        { "get_sleep_time_threshold", GetSleepTimeThreshold },
        { "set_collision_slop",  SetCollisionSlop},
        { "get_collision_slop",  GetCollisionSlop},
        { "set_collision_bias", SetCollisionBias },
        { "get_collision_bias", GetCollisionBias },
        { "set_collision_persistence", SetCollisionPersistence },
        { "get_collision_persistence", GetCollisionPersistence },
        { "get_current_time_step", GetCurrentTimeStep },
        { "is_locked", IsLocked },
        { "step", Step },
        { "get_static_body", GetStaticBody },
        { "add_shape", AddShape },
        { "add_body", AddBody },
        { "add_constraint", AddConstraint },
        { "remove_shape", RemoveShape },
        { "remove_body", RemoveBody },
        { "remove_constraint", RemoveConstraint },
        { "contains_shape", ContainsShape },
        { "contains_body", ContainsBody },
        { "contains_constraint", ContainsConstraint },
        { "reindex_static", ReindexStatic },
        { "reindex_shape", ReindexShape },
        { "reindex_shapes_for_body", ReindexShapesForBody },
        { "use_spatial_hash", UseSpatialHash },
        { "each_body", EachBody },
        { "each_constraint", EachConstraint },
        { "each_shape", EachShape },
        { "add_default_collision_handler", AddDefaultCollisionHandler },
        { "add_collision_handler", AddCollisionHandler },
        { "add_wildcard_handler", AddWildcardHandler },
        { "add_post_step_callback", AddPostStepCallback },
        { "segment_query_first", SegmentQueryFirst },
        { "point_query_nearest", PointQueryNearest },
        { "point_query", PointQuery },
        { "segment_query", SegmentQuery },
        { "bb_query", BBQuery },
        { "shape_query", ShapeQuery },
        { "set_threads", SetThreads },
        { "get_threads", GetThreads },
        { "set_debug_draw_options", SetDebugDrawOptions },
        { "debug_draw", DebugDraw },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { "space_new", Create },
        { "hasty_space_new", CreateHasty },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_space(lua_State *L)
    {
    udata_define(L, SPACE_MT, Methods, MetaMethods);
    luaL_setfuncs(L, Functions, 0);
    }

#if 0
// void* cpSpaceGetUserData(const space_t *space);
// void cpSpaceSetUserData(space_t *space, void* userData);
#endif
