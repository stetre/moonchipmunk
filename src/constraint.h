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

#ifndef constraintDEFINED
#define constraintDEFINED

/* Common functions for constraints */

#define SETDOUBLE(Func, func, what) /* void func(what, double) */   \
static int Func(lua_State *L)                                       \
    {                                                               \
    constraint_t *constraint = check##what(L, 1, NULL);             \
    double val = luaL_checknumber(L, 2);                            \
    func(constraint, val);                                          \
    return 0;                                                       \
    }

#define SETBOOLEAN(Func, func, what)    /* void func(what, bool) */ \
static int Func(lua_State *L)                                       \
    {                                                               \
    constraint_t *constraint = check##what(L, 1, NULL);             \
    int val = checkboolean(L, 2);                                   \
    func(constraint, val);                                          \
    return 0;                                                       \
    }

#define SETVEC(Func, func, what)    /* void func(what, vec_t) */    \
static int Func(lua_State *L)                                       \
    {                                                               \
    vec_t val;                                                      \
    constraint_t *constraint = check##what(L, 1, NULL);             \
    checkvec(L, 2, &val);                                           \
    func(constraint, val);                                          \
    return 0;                                                       \
    }

#define GETDOUBLE(Func, func, what) /* double func(what) */         \
static int Func(lua_State *L)                                       \
    {                                                               \
    constraint_t *constraint = check##what(L, 1, NULL);             \
    double val = func(constraint);                                  \
    lua_pushnumber(L, val);                                         \
    return 1;                                                       \
    }

#define GETBOOLEAN(Func, func, what) /* bool func(what) */          \
static int Func(lua_State *L)                                       \
    {                                                               \
    constraint_t *constraint = check##what(L, 1, NULL);             \
    int val = func(constraint);                                     \
    lua_pushboolean(L, val);                                        \
    return 1;                                                       \
    }

#define GETVEC(Func, func, what) /* vec_t func(what) */             \
static int Func(lua_State *L)                                       \
    {                                                               \
    constraint_t *constraint = check##what(L, 1, NULL);             \
    vec_t val = func(constraint);                                   \
    pushvec(L, &val);                                               \
    return 1;                                                       \
    }

#endif /* constraintDEFINED */
