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

static int freegear_joint(lua_State *L, ud_t *ud)
    {
    constraint_t *constraint = (constraint_t*)ud->handle;
    if(!candestroyconstraint(constraint, ud)) return 0;
    if(!freeuserdata(L, ud, "gear_joint")) return 0;
    constraintdestroy(L, constraint);
    return 0;
    }

static int newgear_joint(lua_State *L, constraint_t *constraint)
    {
    ud_t *ud;
    ud = newuserdata(L, constraint, GEAR_JOINT_MT, "gear_joint");
    ud->parent_ud = NULL;
    ud->destructor = freegear_joint;
    return 1;
    }

static int Create(lua_State *L)
    {
    body_t *a = checkbody(L, 1, NULL);
    body_t *b = checkbody(L, 2, NULL);
    double phase = luaL_checknumber(L, 3);
    double ratio = luaL_checknumber(L, 4);
    constraint_t *constraint = cpGearJointNew(a, b, phase, ratio);
    return newgear_joint(L, constraint);
    }

SETDOUBLE(SetPhase, cpGearJointSetPhase, gear_joint)
SETDOUBLE(SetRatio, cpGearJointSetRatio, gear_joint)
GETDOUBLE(GetPhase, cpGearJointGetPhase, gear_joint)
GETDOUBLE(GetRatio, cpGearJointGetRatio, gear_joint)

DESTROY_FUNC(gear_joint)

static const struct luaL_Reg Methods[] = 
    {
        { "free", Destroy },
        { "set_phase", SetPhase },
        { "set_ratio", SetRatio },
        { "get_phase", GetPhase },
        { "get_ratio", GetRatio },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { "gear_joint_new", Create },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_gear_joint(lua_State *L)
    {
    udata_define(L, GEAR_JOINT_MT, Methods, MetaMethods);
    udata_inherit(L, GEAR_JOINT_MT, CONSTRAINT_MT);
    luaL_setfuncs(L, Functions, 0);
    }

