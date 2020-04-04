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

#ifndef enumsDEFINED
#define enumsDEFINED

/* enums.c */
#define enums_free_all moonchipmunk_enums_free_all
void enums_free_all(lua_State *L);
#define enums_test moonchipmunk_enums_test
int enums_test(lua_State *L, int domain, int arg, int *err);
#define enums_opt moonchipmunk_enums_opt
int enums_opt(lua_State *L, int domain, int arg, int defval);
#define enums_check moonchipmunk_enums_check
int enums_check(lua_State *L, int domain, int arg);
#define enums_push moonchipmunk_enums_push
int enums_push(lua_State *L, int domain, int code);
#define enums_values moonchipmunk_enums_values
int enums_values(lua_State *L, int domain);
#define enums_checklist moonchipmunk_enums_checklist
int* enums_checklist(lua_State *L, int domain, int arg, int *count, int *err);
#define enums_freelist moonchipmunk_enums_freelist
void enums_freelist(lua_State *L, int *list);


/* Enum domains */
#define DOMAIN_                         0
#define DOMAIN_BODY_TYPE                1

#define testbodytype(L, arg, err) enums_test((L), DOMAIN_BODY_TYPE, (arg), (err))
#define optbodytype(L, arg, defval) enums_opt((L), DOMAIN_BODY_TYPE, (arg), (defval))
#define checkbodytype(L, arg) enums_check((L), DOMAIN_BODY_TYPE, (arg))
#define pushbodytype(L, val) enums_push((L), DOMAIN_BODY_TYPE, (int)(val))
#define valuesbodytype(L) enums_values((L), DOMAIN_BODY_TYPE)

#if 0 /* scaffolding 7yy */
#define testxxx(L, arg, err) enums_test((L), DOMAIN_XXX, (arg), (err))
#define optxxx(L, arg, defval) enums_opt((L), DOMAIN_XXX, (arg), (defval))
#define checkxxx(L, arg) enums_check((L), DOMAIN_XXX, (arg))
#define pushxxx(L, val) enums_push((L), DOMAIN_XXX, (int)(val))
#define valuesxxx(L) enums_values((L), DOMAIN_XXX)
    CASE(xxx);

#endif

#endif /* enumsDEFINED */


