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

static int freegroove_joint(lua_State *L, ud_t *ud)
    {
    constraint_t *constraint = (constraint_t*)ud->handle;
    if(!candestroyconstraint(constraint, ud)) return 0;
    if(!freeuserdata(L, ud, "groove_joint")) return 0;
    constraintdestroy(L, constraint);
    return 0;
    }

static int newgroove_joint(lua_State *L, constraint_t *constraint)
    {
    ud_t *ud;
    ud = newuserdata(L, constraint, GROOVE_JOINT_MT, "groove_joint");
    ud->parent_ud = NULL;
    ud->destructor = freegroove_joint;
    return 1;
    }

static int Create(lua_State *L)
    {
    vec_t grooveA, grooveB, anchorB;
    constraint_t *constraint;
    body_t *a = checkbody(L, 1, NULL);
    body_t *b = checkbody(L, 2, NULL);
    checkvec(L, 3, &grooveA);
    checkvec(L, 4, &grooveB);
    checkvec(L, 5, &anchorB);
    constraint = cpGrooveJointNew(a, b, grooveA, grooveB, anchorB);
    return newgroove_joint(L, constraint);
    }

SETVEC(SetGrooveA, cpGrooveJointSetGrooveA, groove_joint)
SETVEC(SetGrooveB, cpGrooveJointSetGrooveB, groove_joint)
SETVEC(SetAnchorB, cpGrooveJointSetAnchorB, groove_joint)
GETVEC(GetGrooveA, cpGrooveJointGetGrooveA, groove_joint)
GETVEC(GetGrooveB, cpGrooveJointGetGrooveB, groove_joint)
GETVEC(GetAnchorB, cpGrooveJointGetAnchorB, groove_joint)

DESTROY_FUNC(groove_joint)

static const struct luaL_Reg Methods[] = 
    {
        { "free", Destroy },
        { "set_groove_a", SetGrooveA },
        { "set_groove_b", SetGrooveB },
        { "set_anchor_b", SetAnchorB },
        { "get_groove_a", GetGrooveA },
        { "get_groove_b", GetGrooveB },
        { "get_anchor_b", GetAnchorB },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg MetaMethods[] = 
    {
        { "__gc",  Destroy },
        { NULL, NULL } /* sentinel */
    };

static const struct luaL_Reg Functions[] = 
    {
        { "groove_joint_new", Create },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_groove_joint(lua_State *L)
    {
    udata_define(L, GROOVE_JOINT_MT, Methods, MetaMethods);
    udata_inherit(L, GROOVE_JOINT_MT, CONSTRAINT_MT);
    luaL_setfuncs(L, Functions, 0);
    }

