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

/* From the Chipmunk Manual:
 * "You will never need to create or free an arbiter. More importantly, because they are
 * entirely managed by the space you should never store a reference to an arbiter as you
 * don’t know when they will be freed or reused. Use them within the callback where they
 * are given to you and then forget about them or copy out the information you need."
 *
 * To avoid creating/destroying userdata at each callback, we use a singleton userdata
 * and a pointer to arbiter_t which we update every time pusharbiter() is called.
 */
static ud_t *Ud = NULL;
static arbiter_t *Arbiter = NULL;
#define HANDLE ((void*)&Arbiter)

static int freearbiter(lua_State *L, ud_t *ud)
    {
    if(!freeuserdata(L, ud, "arbiter")) return 0;
    return 0;
    }

static void newarbiter(lua_State *L)
    {
    Ud = newuserdata(L, HANDLE, ARBITER_MT, "arbiter");
    Ud->parent_ud = NULL;
    Ud->destructor = freearbiter;
    lua_pop(L, 1); /* the userdata left by newuserdata() */
    }

int pusharbiter(lua_State *L, arbiter_t *arbiter)
    {
    Arbiter = arbiter;
    return pushxxx(L, HANDLE);
    }

void invalidatearbiter(lua_State *L, arbiter_t *arbiter)
    {
    Arbiter = NULL;
    (void)L;
    (void)arbiter;
    }


static arbiter_t *checkarbiter(lua_State *L, int arg, ud_t **udp)
    {
    if(!Arbiter) /* function called outside a callback? */
        { luaL_error(L, errstring(ERR_OPERATION)); return NULL; }
    /* HANDLE= */ checkxxx(L, arg, udp, ARBITER_MT);
    return Arbiter;
    }



#define F(Func, func) /* void func(arbiter, double) */  \
static int Func(lua_State *L)                           \
    {                                                   \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);      \
    double val = luaL_checknumber(L, 2);                \
    func(arbiter, val);                                 \
    return 0;                                           \
    }
F(SetRestitution, cpArbiterSetRestitution)
F(SetFriction, cpArbiterSetFriction)
#undef F

#define F(Func, func) /* double func(arbiter) */        \
static int Func(lua_State *L)                           \
    {                                                   \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);      \
    double val = func(arbiter);                         \
    lua_pushnumber(L, val);                             \
    return 1;                                           \
    }
F(GetRestitution, cpArbiterGetRestitution)
F(GetFriction, cpArbiterGetFriction)
F(TotalKE, cpArbiterTotalKE)
#undef F


#define F(Func, func) /* void func(arbiter, vec_t) */   \
static int Func(lua_State *L)                           \
    {                                                   \
    vec_t val;                                          \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);      \
    checkvec(L, 2, &val);                               \
    func(arbiter, val);                                 \
    return 0;                                           \
    }
F(SetSurfaceVelocity, cpArbiterSetSurfaceVelocity)
#undef F


#define F(Func, func) /* vec_t func(arbiter) */         \
static int Func(lua_State *L)                           \
    {                                                   \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);      \
    vec_t val = func(arbiter);                          \
    pushvec(L, &val);                                   \
    return 1;                                           \
    }
F(GetSurfaceVelocity, cpArbiterGetSurfaceVelocity)
F(TotalImpulse, cpArbiterTotalImpulse)
F(GetNormal, cpArbiterGetNormal)
#undef F

#define F(Func, func) /* bool func(arbiter) */          \
static int Func(lua_State *L)                           \
    {                                                   \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);      \
    lua_pushboolean(L, func(arbiter));                  \
    return 1;                                           \
    }
F(Ignore, cpArbiterIgnore)
F(IsFirstContact, cpArbiterIsFirstContact)
F(IsRemoval, cpArbiterIsRemoval)
#undef F

static int GetCount(lua_State *L)
    {
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);
    lua_pushinteger(L, cpArbiterGetCount(arbiter));
    return 1;
    }

static int GetPoints(lua_State *L)
    {
    int i, count;
    vec_t pos;
    double depth;
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);
    count = cpArbiterGetCount(arbiter);
    lua_newtable(L); /* point A */
    lua_newtable(L); /* point B */
    lua_newtable(L); /* depth */
    for(i=0; i <count; i++)
        {
        pos = cpArbiterGetPointA(arbiter, i);
        pushvec(L, &pos);
        lua_rawseti(L, -4, i+1);
        pos = cpArbiterGetPointB(arbiter, i);
        pushvec(L, &pos);
        lua_rawseti(L, -3, i+1);
        depth = cpArbiterGetDepth(arbiter, i);
        lua_pushnumber(L, depth);
        lua_rawseti(L, -2, i+1);
        }
    return 3;
    }

static int SetContactPointSet(lua_State *L)
    {
    cpContactPointSet set;
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);
    checkcontactpointset(L, 2, &set); /* 2=normal, 3={points} */
    cpArbiterSetContactPointSet(arbiter, &set);
    return 0;
    }

static int GetContactPointSet(lua_State *L)
    {
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);
    cpContactPointSet set = cpArbiterGetContactPointSet(arbiter);
    return pushcontactpointset(L, &set); /* normal, {points} */
    }


#define F(Func, func) /* bool func(arbiter, space) */   \
static int Func(lua_State *L)                           \
    {                                                   \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);      \
    space_t *space = checkspace(L, 2, NULL);            \
    lua_pushboolean(L, func(arbiter, space));           \
    return 1;                                           \
    }
F(CallWildcardBeginA, cpArbiterCallWildcardBeginA)
F(CallWildcardBeginB, cpArbiterCallWildcardBeginB)
F(CallWildcardPreSolveA, cpArbiterCallWildcardPreSolveA)
F(CallWildcardPreSolveB, cpArbiterCallWildcardPreSolveB)
#undef F


#define F(Func, func) /* void func(arbiter, space) */   \
static int Func(lua_State *L)                           \
    {                                                   \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);      \
    space_t *space = checkspace(L, 2, NULL);            \
    func(arbiter, space);                               \
    return 0;                                           \
    }
F(CallWildcardPostSolveA, cpArbiterCallWildcardPostSolveA)
F(CallWildcardPostSolveB, cpArbiterCallWildcardPostSolveB)
F(CallWildcardSeparateA, cpArbiterCallWildcardSeparateA)
F(CallWildcardSeparateB, cpArbiterCallWildcardSeparateB)
#undef F


#define F(Func, func, what)                                             \
static int Func(lua_State *L) /* void func(arbiter, what**, what**) */  \
    {                                                                   \
    what##_t *a, *b;                                                    \
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);                      \
    func(arbiter, &a, &b);                                              \
    push##what(L, a);                                                   \
    push##what(L, b);                                                   \
    return 2;                                                           \
    }
F(GetShapes, cpArbiterGetShapes, shape)
F(GetBodies, cpArbiterGetBodies, body)
#undef F

static int SetUserIndex(lua_State *L)
    {
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);
    intptr_t data = luaL_checkinteger(L, 2);
    cpArbiterSetUserData(arbiter, (cpDataPointer)data);
    return 0;
    }

static int GetUserIndex(lua_State *L)
    {
    arbiter_t *arbiter = checkarbiter(L, 1, NULL);
    intptr_t data = (intptr_t)cpArbiterGetUserData(arbiter);
    lua_pushinteger(L, data);
    return 1;
    }

RAW_FUNC(arbiter)
PARENT_FUNC(arbiter)
DESTROY_FUNC(arbiter)

static const struct luaL_Reg Methods[] = 
    {
        { "raw", Raw },
        { "parent", Parent },
        { "set_restitution", SetRestitution },
        { "set_friction", SetFriction },
        { "get_restitution", GetRestitution },
        { "get_friction", GetFriction },
        { "total_ke", TotalKE },
        { "set_surface_velocity", SetSurfaceVelocity },
        { "get_surface_velocity", GetSurfaceVelocity },
        { "total_impulse", TotalImpulse },
        { "get_normal", GetNormal },
        { "ignore", Ignore },
        { "is_first_contact", IsFirstContact },
        { "is_removal", IsRemoval },
        { "get_count", GetCount },
        { "get_points", GetPoints },
        { "set_contact_point_set", SetContactPointSet },
        { "get_contact_point_set", GetContactPointSet },
        { "call_wildcard_begin_a", CallWildcardBeginA },
        { "call_wildcard_begin_b", CallWildcardBeginB },
        { "call_wildcard_pre_solve_a", CallWildcardPreSolveA },
        { "call_wildcard_pre_solve_b", CallWildcardPreSolveB },
        { "call_wildcard_post_solve_a", CallWildcardPostSolveA },
        { "call_wildcard_post_solve_b", CallWildcardPostSolveB },
        { "call_wildcard_separate_a", CallWildcardSeparateA },
        { "call_wildcard_separate_b", CallWildcardSeparateB },
        { "get_shapes", GetShapes },
        { "get_bodies", GetBodies },
        { "set_user_index", SetUserIndex },
        { "get_user_index", GetUserIndex },
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

void moonchipmunk_open_arbiter(lua_State *L)
    {
    udata_define(L, ARBITER_MT, Methods, MetaMethods);
    luaL_setfuncs(L, Functions, 0);
    newarbiter(L);
    }

#if 0
//cpDataPointer cpArbiterGetUserData(const arbiter_t *arbiter);
//void cpArbiterSetUserData(arbiter_t *arbiter, cpDataPointer userData);
#endif

