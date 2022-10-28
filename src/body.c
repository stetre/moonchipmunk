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

static void removeconstraint(body_t *body, constraint_t *constraint, void *data)
    { cpSpaceRemoveConstraint((space_t*)data, constraint); (void)body; }

static void removeshape(body_t *body, shape_t *shape, void *data)
    { cpSpaceRemoveShape((space_t*)data, shape); (void)body; }

int freebody(lua_State *L, ud_t *ud)
    {
    space_t *space;
    body_t *body = (body_t*)ud->handle;
    if(!IsValid(ud)) return 0;
    space = cpBodyGetSpace(body);
    if(space && cpSpaceIsLocked(space)) return 0; /* leave it to post step */
//  freechildren(L, _MT, ud);
    if(!freeuserdata(L, ud, "body")) return 0;
    if(!IsBorrowed(ud))
        {
        if(space)
            {
            if(cpSpaceIsLocked(space)) return failure(L, ERR_OPERATION);
            /* Remove from the space all shapes and constraints connected to the body,
             * and the body itself. */
            cpBodyEachConstraint(body, removeconstraint, space);
            cpBodyEachShape(body, removeshape, space);
            cpSpaceRemoveBody(space, body);
            }
        cpBodyFree(body);
        }
    return 0;
    }

int newbody(lua_State *L, body_t *body, int borrowed)
    {
    ud_t *ud;
    ud = newuserdata(L, body, BODY_MT, "body");
    ud->parent_ud = NULL;
    ud->destructor = freebody;
    if(borrowed) MarkBorrowed(ud);
    return 1;
    }

static int Create(lua_State *L)
    {
    double mass = luaL_checknumber(L, 1);
    double moment = luaL_checknumber(L, 2);
    body_t *body = cpBodyNew(mass, moment);
    return newbody(L, body, 0);
    }

static int CreateKinematic(lua_State *L)
    {
    body_t *body = cpBodyNewKinematic();
    return newbody(L, body, 0);
    }

static int CreateStatic(lua_State *L)
    {
    body_t *body = cpBodyNewStatic();
    return newbody(L, body, 0);
    }

#define F(Func, func) /* void func(body, double) */     \
static int Func(lua_State *L)                           \
    {                                                   \
    body_t *body = checkbody(L, 1, NULL);               \
    double val = luaL_checknumber(L, 2);                \
    func(body, val);                                    \
    return 0;                                           \
    }
F(SetMass, cpBodySetMass)
F(SetMoment, cpBodySetMoment)
F(SetAngle, cpBodySetAngle)
F(SetAngularVelocity, cpBodySetAngularVelocity)
F(SetTorque, cpBodySetTorque)
F(UpdatePosition, cpBodyUpdatePosition)
#undef F

#define F(Func, func) /* double func(body) */           \
static int Func(lua_State *L)                           \
    {                                                   \
    body_t *body = checkbody(L, 1, NULL);               \
    double val = func(body);                            \
    lua_pushnumber(L, val);                             \
    return 1;                                           \
    }
F(GetMass, cpBodyGetMass)
F(GetMoment, cpBodyGetMoment)
F(GetAngle, cpBodyGetAngle)
F(GetAngularVelocity, cpBodyGetAngularVelocity)
F(GetTorque, cpBodyGetTorque)
F(KineticEnergy, cpBodyKineticEnergy)
#undef F

static int IsSleeping(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    int val = cpBodyIsSleeping(body);
    lua_pushboolean(L, val);
    return 1;
    }

static int GetIdleTime(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    lua_pushnumber(L, body->sleeping.idleTime);
    return 1;
    }

#define F(Func, func) /* void func(body, vec_t) */      \
static int Func(lua_State *L)                           \
    {                                                   \
    vec_t val;                                          \
    body_t *body = checkbody(L, 1, NULL);               \
    checkvec(L, 2, &val);                               \
    func(body, val);                                    \
    return 0;                                           \
    }
F(SetPosition, cpBodySetPosition)
F(SetCenterOfGravity, cpBodySetCenterOfGravity)
F(SetVelocity, cpBodySetVelocity)
F(SetForce, cpBodySetForce)
#undef F

#define F(Func, func) /* vec_t func(body) */            \
static int Func(lua_State *L)                           \
    {                                                   \
    body_t *body = checkbody(L, 1, NULL);               \
    vec_t val = func(body);                             \
    pushvec(L, &val);                                   \
    return 1;                                           \
    }
F(GetPosition, cpBodyGetPosition)
F(GetCenterOfGravity, cpBodyGetCenterOfGravity)
F(GetVelocity, cpBodyGetVelocity)
F(GetForce, cpBodyGetForce)
F(GetRotation, cpBodyGetRotation)
#undef F

#define F(Func, func) /* void func(body, vec_t, vec_t) */\
static int Func(lua_State *L)                           \
    {                                                   \
    vec_t val1, val2;                                   \
    body_t *body = checkbody(L, 1, NULL);               \
    checkvec(L, 2, &val1);                              \
    checkvec(L, 3, &val2);                              \
    func(body, val1, val2);                             \
    return 0;                                           \
    }
F(ApplyForceAtWorldPoint, cpBodyApplyForceAtWorldPoint)
F(ApplyForceAtLocalPoint, cpBodyApplyForceAtLocalPoint)
F(ApplyImpulseAtWorldPoint, cpBodyApplyImpulseAtWorldPoint)
F(ApplyImpulseAtLocalPoint, cpBodyApplyImpulseAtLocalPoint)
#undef F

#define F(Func, func) /* vec_t func(body, vec_t) */     \
static int Func(lua_State *L)                           \
    {                                                   \
    vec_t val, res;                                     \
    body_t *body = checkbody(L, 1, NULL);               \
    checkvec(L, 2, &val);                               \
    res = func(body, val);                              \
    pushvec(L, &res);                                   \
    return 1;                                           \
    }
F(LocalToWorld, cpBodyLocalToWorld)
F(WorldToLocal, cpBodyWorldToLocal)
F(GetVelocityAtWorldPoint, cpBodyGetVelocityAtWorldPoint)
F(GetVelocityAtLocalPoint, cpBodyGetVelocityAtLocalPoint)
#undef F

static int Sleeep(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    cpBodySleep(body);
    return 0;
    }

static int SleepWithGroup(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    body_t *group = optbody(L, 2, NULL);
    cpBodySleepWithGroup(body, group);
    return 0;
    }

static int Activate(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    cpBodyActivate(body);
    return 0;
    }

static int ActivateStatic(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    shape_t *filter = optshape(L, 2, NULL);
    cpBodyActivateStatic(body, filter);
    return 0;
    }

static int GetSpace(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    space_t * space = cpBodyGetSpace(body);
    if(!space) lua_pushnil(L);
    else pushspace(L, space);
    return 1;
    }

static int SetType(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    cpBodyType type = checkbodytype(L, 2);
    cpBodySetType(body, type);
    return 0;
    }

static int GetType(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    cpBodyType type = cpBodyGetType(body);
    pushbodytype(L, type);
    return 1;
    }

static int UpdateVelocity(lua_State *L)
    {
    vec_t gravity;
    double damping, dt;
    body_t *body = checkbody(L, 1, NULL);
    checkvec(L, 2, &gravity);
    damping = luaL_checknumber(L, 3);
    dt = luaL_checknumber(L, 4);
    cpBodyUpdateVelocity(body, gravity, damping, dt);
    return 0;
    }

#define F(Func, What, what)                                                 \
static void IteratorFunc##What(body_t *body, what##_t *what, void *data)    \
    {                                                                       \
    lua_State *L = moonchipmunk_L;                                          \
    int top = lua_gettop(L);                                                \
    lua_pushvalue(L, 2);    /* the function */                              \
    pushbody(L, body);                                                      \
    push##what(L, what);                                                    \
    (void)data;                                                             \
    if(lua_pcall(L, 2, 0, 0) != LUA_OK)                                     \
        { lua_error(L); return; }                                           \
    lua_settop(L, top);                                                     \
    }                                                                       \
static int Func(lua_State *L)                                               \
    {                                                                       \
    body_t *body = checkbody(L, 1, NULL);                                   \
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);          \
    cpBodyEach##What(body, IteratorFunc##What, NULL);                       \
    return 0;                                                               \
    }
F(EachShape, Shape, shape)
F(EachConstraint, Constraint, constraint)
#undef F

static void IteratorFuncArbiter(body_t *body, arbiter_t *arbiter, void *data)
    {
    lua_State *L = moonchipmunk_L;
    int top = lua_gettop(L);
    lua_pushvalue(L, 2);    /* the function */
    pushbody(L, body);
    pusharbiter(L, arbiter);
    (void)data;
    if(lua_pcall(L, 2, 0, 0) != LUA_OK)
        { invalidatearbiter(L, arbiter); lua_error(L); return; }
    invalidatearbiter(L, arbiter);
    lua_settop(L, top);
    }

static int EachArbiter(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);
    cpBodyEachArbiter(body, IteratorFuncArbiter, NULL);
    return 0;
    }

static void BodyVelocityFunc(body_t *body, vec_t gravity, double damping, double dt)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    ud_t *ud = userdata(body);
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    pushbody(L, body);
    pushvec(L, &gravity);
    lua_pushnumber(L, damping);
    lua_pushnumber(L, dt);
    rc = lua_pcall(L, 4, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    lua_settop(L, top);
    }

static int SetVelocityUpdateFunc(lua_State *L)
    {
    ud_t *ud;
    body_t *body = checkbody(L, 1, &ud);
    if(lua_isnoneornil(L, 2))
        {
        Unreference(L, ud->ref1);
        cpBodySetVelocityUpdateFunc(body, cpBodyUpdateVelocity);
        return 0;
        }
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref1);
    cpBodySetVelocityUpdateFunc(body, BodyVelocityFunc);
    return 0;
    }

static void BodyPositionFunc(body_t *body, double dt)
    {
    int rc;
    lua_State *L = moonchipmunk_L;
    ud_t *ud = userdata(body);
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref2);
    pushbody(L, body);
    lua_pushnumber(L, dt);
    rc = lua_pcall(L, 2, 0, 0);
    if(rc!=LUA_OK) lua_error(L);
    lua_settop(L, top);
    }

static int SetPositionUpdateFunc(lua_State *L)
    {
    ud_t *ud;
    body_t *body = checkbody(L, 1, &ud);
    if(lua_isnoneornil(L, 2))
        {
        Unreference(L, ud->ref2);
        cpBodySetPositionUpdateFunc(body, cpBodyUpdatePosition);
        return 0;
        }
    if(!lua_isfunction(L, 2)) return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref2);
    cpBodySetPositionUpdateFunc(body, BodyPositionFunc);
    return 0;
    }

static int SetUserData(lua_State *L)
    {
    intptr_t ref;
    body_t *body = checkbody(L, 1, NULL);
    luaL_checktype(L, 2, LUA_TTABLE);
    ref = luaL_ref(L, LUA_REGISTRYINDEX);
    cpBodySetUserData(body, (cpDataPointer*)ref);
    return 0;
    }

static int GetUserData(lua_State *L)
    {
    body_t *body = checkbody(L, 1, NULL);
    cpDataPointer * ptr = cpBodyGetUserData(body);
    if(!ptr) lua_pushnil(L);
    else lua_rawgeti(L, LUA_REGISTRYINDEX, (lua_Integer)ptr);
    return 1;
    }

RAW_FUNC(body)
PARENT_FUNC(body)
DESTROY_FUNC(body)

static const struct luaL_Reg Methods[] = 
    {
        { "raw", Raw },
        { "parent", Parent },
        { "free", Destroy },
        { "set_mass", SetMass },
        { "set_moment", SetMoment },
        { "set_angle", SetAngle },
        { "set_angular_velocity", SetAngularVelocity },
        { "set_torque", SetTorque },
        { "update_position", UpdatePosition },
        { "get_mass", GetMass },
        { "get_moment", GetMoment },
        { "get_angle", GetAngle },
        { "get_angular_velocity", GetAngularVelocity },
        { "get_torque", GetTorque },
        { "kinetic_energy", KineticEnergy },
        { "is_sleeping", IsSleeping },
        { "get_idle_time", GetIdleTime },
        { "set_position", SetPosition },
        { "set_center_of_gravity", SetCenterOfGravity },
        { "set_velocity", SetVelocity },
        { "set_force", SetForce },
        { "get_position", GetPosition },
        { "get_center_of_gravity", GetCenterOfGravity },
        { "get_velocity", GetVelocity },
        { "get_force", GetForce },
        { "get_rotation", GetRotation },
        { "apply_force_at_world_point", ApplyForceAtWorldPoint },
        { "apply_force_at_local_point", ApplyForceAtLocalPoint },
        { "apply_impulse_at_world_point", ApplyImpulseAtWorldPoint },
        { "apply_impulse_at_local_point", ApplyImpulseAtLocalPoint },
        { "local_to_world", LocalToWorld },
        { "world_to_local", WorldToLocal },
        { "get_velocity_at_world_point", GetVelocityAtWorldPoint },
        { "get_velocity_at_local_point", GetVelocityAtLocalPoint },
        { "sleep", Sleeep },
        { "sleep_with_group", SleepWithGroup },
        { "activate", Activate },
        { "activate_static", ActivateStatic },
        { "get_space", GetSpace },
        { "set_type", SetType },
        { "get_type", GetType },
        { "update_velocity", UpdateVelocity },
        { "each_shape", EachShape },
        { "each_constraint", EachConstraint },
        { "each_arbiter", EachArbiter },
        { "set_velocity_update_func", SetVelocityUpdateFunc },
        { "set_position_update_func", SetPositionUpdateFunc },
        { "set_user_data", SetUserData },
        { "get_user_data", GetUserData },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { "body_new", Create },
        { "body_new_kinematic", CreateKinematic },
        { "body_new_static", CreateStatic },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_body(lua_State *L)
    {
    udata_define(L, BODY_MT, Methods, MetaMethods);
    luaL_setfuncs(L, Functions, 0);
    }
