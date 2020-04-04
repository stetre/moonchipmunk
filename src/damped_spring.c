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
#include "constraint.h"

static int freedamped_spring(lua_State *L, ud_t *ud)
    {
    constraint_t *constraint = (constraint_t*)ud->handle;
    if(!candestroyconstraint(constraint, ud)) return 0;
    if(!freeuserdata(L, ud, "damped_spring")) return 0;
    constraintdestroy(L, constraint);
    return 0;
    }

static int newdamped_spring(lua_State *L, constraint_t *constraint)
    {
    ud_t *ud;
    ud = newuserdata(L, constraint, DAMPED_SPRING_MT, "damped_spring");
    ud->parent_ud = NULL;
    ud->destructor = freedamped_spring;
    return 1;
    }

static int Create(lua_State *L)
    {
    vec_t anchorA, anchorB;
    double restLength, stiffness, damping;
    constraint_t *constraint;
    body_t *a = checkbody(L, 1, NULL);
    body_t *b = checkbody(L, 2, NULL);
    checkvec(L, 3, &anchorA);
    checkvec(L, 4, &anchorB);
    restLength = luaL_checknumber(L, 5);
    stiffness = luaL_checknumber(L, 6);
    damping = luaL_checknumber(L, 7);
    constraint = cpDampedSpringNew(a, b, anchorA, anchorB, restLength, stiffness, damping);
    return newdamped_spring(L, constraint);
    }

SETVEC(SetAnchorA, cpDampedSpringSetAnchorA, damped_spring)
SETVEC(SetAnchorB, cpDampedSpringSetAnchorB, damped_spring)
GETVEC(GetAnchorA, cpDampedSpringGetAnchorA, damped_spring)
GETVEC(GetAnchorB, cpDampedSpringGetAnchorB, damped_spring)
SETDOUBLE(SetRestLength, cpDampedSpringSetRestLength, damped_spring)
SETDOUBLE(SetStiffness, cpDampedSpringSetStiffness, damped_spring)
SETDOUBLE(SetDamping, cpDampedSpringSetDamping, damped_spring)
GETDOUBLE(GetRestLength, cpDampedSpringGetRestLength, damped_spring)
GETDOUBLE(GetStiffness, cpDampedSpringGetStiffness, damped_spring)
GETDOUBLE(GetDamping, cpDampedSpringGetDamping, damped_spring)

static double ForceCallback(constraint_t *constraint, double dist) /* ud->ref3 */
    {
#define L moonchipmunk_L
    double result;
    int top = lua_gettop(L);
    ud_t *ud = userdata(constraint);
    if(!ud) { unexpected(L); return 0.0f; } 
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref3);
    pushconstraint(L, constraint);
    lua_pushnumber(L, dist);
    if(lua_pcall(L, 2, 1, 0) != LUA_OK)
        { lua_error(L); return 0.0f; }
    result = luaL_checknumber(L, -1);
    lua_settop(L, top);
    return result;
#undef L
    }

static int SetSpringForceFunc(lua_State *L)
    {
    ud_t *ud;
    constraint_t *constraint = checkdamped_spring(L, 1, &ud);
    if(lua_isnoneornil(L, 2)) /* remove callback */
        {
        if(ud->ref3!=LUA_NOREF)
            { cpDampedSpringSetSpringForceFunc(constraint, NULL); Unreference(L, ud->ref3); }
        return 0;
        }
    if(!lua_isfunction(L, 2))
        return argerror(L, 2, ERR_FUNCTION);
    Reference(L, 2, ud->ref3);
    cpDampedSpringSetSpringForceFunc(constraint, ForceCallback);
    return 0;
    }

static int GetSpringForceFunc(lua_State *L)
    {
    ud_t *ud;
    (void)checkdamped_spring(L, 1, &ud);
    lua_rawgeti(L, LUA_REGISTRYINDEX, ud->ref3);
    return 1;
    }

DESTROY_FUNC(damped_spring)

static const struct luaL_Reg Methods[] = 
    {
        { "free", Destroy },
        { "set_anchor_a", SetAnchorA },
        { "set_anchor_b", SetAnchorB },
        { "get_anchor_a", GetAnchorA },
        { "get_anchor_b", GetAnchorB },
        { "set_rest_length", SetRestLength },
        { "set_stiffness", SetStiffness },
        { "set_damping", SetDamping },
        { "get_rest_length", GetRestLength },
        { "get_stiffness", GetStiffness },
        { "get_damping", GetDamping },
        { "set_spring_force_func", SetSpringForceFunc },
        { "get_spring_force_func", GetSpringForceFunc },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { "damped_spring_new", Create },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_damped_spring(lua_State *L)
    {
    udata_define(L, DAMPED_SPRING_MT, Methods, MetaMethods);
    udata_inherit(L, DAMPED_SPRING_MT, CONSTRAINT_MT);
    luaL_setfuncs(L, Functions, 0);
    }

