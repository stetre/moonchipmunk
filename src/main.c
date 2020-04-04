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

lua_State *moonchipmunk_L;

static void AtExit(void)
    {
    if(moonchipmunk_L)
        {
        enums_free_all(moonchipmunk_L);
        moonchipmunk_L = NULL;
        }
    }
 
static int AddVersions(lua_State *L)
    {
    lua_pushstring(L, "_VERSION");
    lua_pushstring(L, "MoonChipmunk "MOONCHIPMUNK_VERSION);
    lua_settable(L, -3);


    lua_pushstring(L, "_CHIPMUNK_VERSION");
//    lua_pushfstring(L, "Chipmunk %d.%d.%d",
//          CP_VERSION_MAJOR, CP_VERSION_MINOR, CP_VERSION_RELEASE);
    lua_pushfstring(L, "Chipmunk %s", cpVersionString);
    lua_settable(L, -3);

    return 0;
    }
 
static int AddConstants(lua_State *L)
    {
    lua_pushinteger(L, CP_NO_GROUP);
    lua_setfield(L, -2, "NO_GROUP");

    lua_pushinteger(L, CP_ALL_CATEGORIES);
    lua_setfield(L, -2, "ALL_CATEGORIES");

    lua_pushinteger(L, CP_WILDCARD_COLLISION_TYPE);
    lua_setfield(L, -2, "WILDCARD_COLLISION_TYPE");
    return 0;
    }



static int IsGlmathCompat(lua_State *L)
    {
    lua_pushboolean(L, isglmathcompat());
    return 1;
    }

static int GlmathCompat(lua_State *L)
    {
    int on = checkboolean(L, 1);
    glmathcompat(L, on);
    return 0;
    }

static const struct luaL_Reg Functions[] = 
    {
        { "is_glmath_compat", IsGlmathCompat },
        { "glmath_compat", GlmathCompat },
        { NULL, NULL } /* sentinel */
    };

int luaopen_moonchipmunk(lua_State *L)
/* Lua calls this function to load the module */
    {
    moonchipmunk_L = L;

    moonchipmunk_utils_init(L);
    atexit(AtExit);

    lua_newtable(L); /* the module table */
    moonchipmunk_open_enums(L);
    moonchipmunk_open_flags(L);
    AddVersions(L);
    AddConstants(L);
    luaL_setfuncs(L, Functions, 0);
    moonchipmunk_open_tracing(L);
    moonchipmunk_open_misc(L);
    moonchipmunk_open_space(L);
    moonchipmunk_open_body(L);
    moonchipmunk_open_shape(L);
    moonchipmunk_open_circle(L);
    moonchipmunk_open_segment(L);
    moonchipmunk_open_poly(L);
    moonchipmunk_open_constraint(L);
    moonchipmunk_open_pin_joint(L);
    moonchipmunk_open_slide_joint(L);
    moonchipmunk_open_pivot_joint(L);
    moonchipmunk_open_groove_joint(L);
    moonchipmunk_open_damped_spring(L);
    moonchipmunk_open_damped_rotary_spring(L);
    moonchipmunk_open_rotary_limit_joint(L);
    moonchipmunk_open_ratchet_joint(L);
    moonchipmunk_open_gear_joint(L);
    moonchipmunk_open_simple_motor(L);
    moonchipmunk_open_arbiter(L);
    moonchipmunk_open_collision_handler(L);

#if 0 //@@
    /* Add functions implemented in Lua */
    lua_pushvalue(L, -1); lua_setglobal(L, "moonchipmunk");
    if(luaL_dostring(L, "require('moonchipmunk.datastructs')") != 0) lua_error(L);
    lua_pushnil(L);  lua_setglobal(L, "moonchipmunk");
#endif

    return 1;
    }

