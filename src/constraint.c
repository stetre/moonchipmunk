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

int candestroyconstraint(constraint_t *constraint, ud_t *ud)
    {
    space_t *space;
    if(!IsValid(ud)) return 0; /* already destroyed */
    space = cpConstraintGetSpace(constraint);
    if(space && cpSpaceIsLocked(space)) return 0; /* leave it to post step callbacks */
    return 1;
    }

int constraintdestroy(lua_State *L, constraint_t *constraint)
    {
    space_t *space = cpConstraintGetSpace(constraint);
    if(space) 
        {
        if(cpSpaceIsLocked(space)) return failure(L, ERR_OPERATION);
        cpSpaceRemoveConstraint(space, constraint);
        }
    cpConstraintFree(constraint);
    return 0;
    }

#define F(What)                                                 \
static int Is##What(lua_State *L)                               \
    {                                                           \
    constraint_t *constraint = checkconstraint(L, 1, NULL);     \
    lua_pushboolean(L, cpConstraintIs##What(constraint));       \
    return 1;                                                   \
    }
F(PinJoint)
F(SlideJoint)
F(PivotJoint)
F(GrooveJoint)
F(DampedSpring)
F(DampedRotarySpring)
F(RotaryLimitJoint)
F(RatchetJoint)
F(GearJoint)
F(SimpleMotor)
#undef F

static int GetSpace(lua_State *L)
    {
    constraint_t *constraint = checkconstraint(L, 1, NULL);
    space_t *space = cpConstraintGetSpace(constraint);
    if(!space) lua_pushnil(L);
    else pushspace(L, space);
    return 1;
    }

static int GetBodyA(lua_State *L)
    {
    constraint_t *constraint = checkconstraint(L, 1, NULL);
    body_t *body = cpConstraintGetBodyA(constraint);
    pushbody(L, body);
    return 1;
    }

static int GetBodyB(lua_State *L)
    {
    constraint_t *constraint = checkconstraint(L, 1, NULL);
    body_t *body = cpConstraintGetBodyB(constraint);
    pushbody(L, body);
    return 1;
    }

static int GetBodies(lua_State *L)
    {
    constraint_t *constraint = checkconstraint(L, 1, NULL);
    body_t *bodyA = cpConstraintGetBodyA(constraint);
    body_t *bodyB = cpConstraintGetBodyB(constraint);
    pushbody(L, bodyA);
    pushbody(L, bodyB);
    return 2;
    }


#define F(Func, func)                                       \
static int Func(lua_State *L)                               \
    {                                                       \
    constraint_t *constraint = checkconstraint(L, 1, NULL); \
    double val = luaL_checknumber(L, 2);                    \
    func(constraint, val);                                  \
    return 0;                                               \
    }
F(SetMaxForce, cpConstraintSetMaxForce)
F(SetErrorBias, cpConstraintSetErrorBias)
F(SetMaxBias, cpConstraintSetMaxBias)
#undef F


#define F(Func, func)                                       \
static int Func(lua_State *L)                               \
    {                                                       \
    constraint_t *constraint = checkconstraint(L, 1, NULL); \
    double val = func(constraint);                          \
    lua_pushnumber(L, val);                                 \
    return 1;                                               \
    }
F(GetMaxForce, cpConstraintGetMaxForce)
F(GetErrorBias, cpConstraintGetErrorBias)
F(GetMaxBias, cpConstraintGetMaxBias)
F(GetImpulse, cpConstraintGetImpulse)
#undef F

static int SetCollideBodies(lua_State *L)
    {
    constraint_t *constraint = checkconstraint(L, 1, NULL);
    int val = checkboolean(L, 2);
    cpConstraintSetCollideBodies(constraint, val);
    return 0;
    }

static int GetCollideBodies(lua_State *L)
    {
    constraint_t *constraint = checkconstraint(L, 1, NULL);
    lua_pushboolean(L, cpConstraintGetCollideBodies(constraint));
    return 1;
    }


static void PreSolveCallback(constraint_t *constraint, space_t *space) /* ud->ref1 */
    {
#define L moonchipmunk_L
    int top = lua_gettop(L);
    ud_t *ud = userdata(constraint);
    if(!ud) { unexpected(L); return; } 
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    pushconstraint(L, constraint);
    pushspace(L, space);
    if(lua_pcall(L, 2, 0, 0) != LUA_OK)
        { lua_error(L); return; }
    lua_settop(L, top);
    return;
#undef L
    }

static int SetPreSolveFunc(lua_State *L)
    {
    ud_t *ud;
    constraint_t *constraint = checkconstraint(L, 1, &ud);
    if(lua_isnoneornil(L, 2)) /* remove callback */
        {
        if(ud->ref1!=LUA_NOREF)
            { cpConstraintSetPreSolveFunc(constraint, NULL); Unreference(L, ud->ref1); }
        return 0;
        }
    if(!lua_isfunction(L, 2))
        return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref1);
    cpConstraintSetPreSolveFunc(constraint, PreSolveCallback);
    return 0;
    }

static int GetPreSolveFunc(lua_State *L)
    {
    ud_t *ud;
    (void)checkconstraint(L, 1, &ud);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref1);
    return 1;
    }

static void PostSolveCallback(constraint_t *constraint, space_t *space) /* ud->ref2 */
    {
#define L moonchipmunk_L
    int top = lua_gettop(L);
    ud_t *ud = userdata(constraint);
    if(!ud) { unexpected(L); return; } 
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref2);
    pushconstraint(L, constraint);
    pushspace(L, space);
    if(lua_pcall(L, 2, 0, 0) != LUA_OK)
        { lua_error(L); return; }
    lua_settop(L, top);
    return;
#undef L
    }

static int SetPostSolveFunc(lua_State *L)
    {
    ud_t *ud;
    constraint_t *constraint = checkconstraint(L, 1, &ud);
    if(lua_isnoneornil(L, 2)) /* remove callback */
        {
        if(ud->ref2!=LUA_NOREF)
            { cpConstraintSetPostSolveFunc(constraint, NULL); Unreference(L, ud->ref2); }
        return 0;
        }
    if(!lua_isfunction(L, 2))
        return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref2);
    cpConstraintSetPostSolveFunc(constraint, PostSolveCallback);
    return 0;
    }

static int GetPostSolveFunc(lua_State *L)
    {
    ud_t *ud;
    (void)checkconstraint(L, 1, &ud);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref2);
    return 1;
    }

RAW_FUNC(constraint)
PARENT_FUNC(constraint)
DESTROY_FUNC(constraint)

static const struct luaL_Reg Methods[] = 
    {
        { "raw", Raw },
        { "parent", Parent },
        { "free", Destroy },
        { "is_pin_joint", IsPinJoint },
        { "is_slide_joint", IsSlideJoint },
        { "is_pivot_joint", IsPivotJoint },
        { "is_groove_joint", IsGrooveJoint },
        { "is_damped_spring", IsDampedSpring },
        { "is_damped_rotary_spring", IsDampedRotarySpring },
        { "is_rotary_limit_joint", IsRotaryLimitJoint },
        { "is_ratchet_joint", IsRatchetJoint },
        { "is_gear_joint", IsGearJoint },
        { "is_simple_motor", IsSimpleMotor },
        { "get_space", GetSpace },
        { "get_body_a", GetBodyA },
        { "get_body_b", GetBodyB },
        { "get_bodies", GetBodies },
        { "set_max_force", SetMaxForce },
        { "set_error_bias", SetErrorBias },
        { "set_max_bias", SetMaxBias },
        { "get_max_force", GetMaxForce },
        { "get_error_bias", GetErrorBias },
        { "get_max_bias", GetMaxBias },
        { "get_impulse", GetImpulse },
        { "set_collide_bodies", SetCollideBodies },
        { "get_collide_bodies", GetCollideBodies },
        { "set_pre_solve_func", SetPreSolveFunc },
        { "get_pre_solve_func", GetPreSolveFunc },
        { "set_post_solve_func", SetPostSolveFunc },
        { "get_post_solve_func", GetPostSolveFunc },
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

void moonchipmunk_open_constraint(lua_State *L)
    {
    udata_define(L, CONSTRAINT_MT, Methods, MetaMethods);
    luaL_setfuncs(L, Functions, 0);
    }

#if 0
//cpDataPointer cpConstraintGetUserData(const constraint_t *constraint);
//void cpConstraintSetUserData(constraint_t *constraint, cpDataPointer userData);
#endif
