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

#ifndef internalDEFINED
#define internalDEFINED

#include <string.h>
#include <stdlib.h>
#include <time.h>
#include "moonchipmunk.h"

#define TOSTR_(x) #x
#define TOSTR(x) TOSTR_(x)

#include "tree.h"
#include "objects.h"
#include "enums.h"

/* Note: all the dynamic symbols of this library (should) start with 'moonchipmunk_' .
 * The only exception is the luaopen_moonchipmunk() function, which is searched for
 * with that name by Lua.
 * MoonChipmunk's string references on the Lua registry also start with 'moonchipmunk_'.
 */

#if 0
/* .c */
#define  moonchipmunk_
#endif

/* flags.c */
#define checkflags(L, arg) luaL_checkinteger((L), (arg))
#define optflags(L, arg, defval) luaL_optinteger((L), (arg), (defval))
#define pushflags(L, val) lua_pushinteger((L), (val))

/* cpCollisionType */
#define checkcollisiontype(L, arg) (cpCollisionType)luaL_checkinteger((L), (arg))
#define optcollisiontype(L, arg, defval) luaL_optinteger((L), (arg), (defval))
#define pushcollisiontype(L, val) lua_pushinteger((L), (val))

/* utils.c */
void moonchipmunk_utils_init(lua_State *L);
#define copytable moonchipmunk_copytable
int copytable(lua_State *L);
#define noprintf moonchipmunk_noprintf
int noprintf(const char *fmt, ...); 
#define now moonchipmunk_now
double now(void);
#define sleeep moonchipmunk_sleeep
void sleeep(double seconds);
#define since(t) (now() - (t))
#define notavailable moonchipmunk_notavailable
int notavailable(lua_State *L, ...);
#define Malloc moonchipmunk_Malloc
void *Malloc(lua_State *L, size_t size);
#define MallocNoErr moonchipmunk_MallocNoErr
void *MallocNoErr(lua_State *L, size_t size);
#define Strdup moonchipmunk_Strdup
char *Strdup(lua_State *L, const char *s);
#define Free moonchipmunk_Free
void Free(lua_State *L, void *ptr);
#define checkboolean moonchipmunk_checkboolean
int checkboolean(lua_State *L, int arg);
#define testboolean moonchipmunk_testboolean
int testboolean(lua_State *L, int arg, int *err);
#define optboolean moonchipmunk_optboolean
int optboolean(lua_State *L, int arg, int d);
#define checklightuserdata moonchipmunk_checklightuserdata
void *checklightuserdata(lua_State *L, int arg);
#define checklightuserdataorzero moonchipmunk_checklightuserdataorzero
void *checklightuserdataorzero(lua_State *L, int arg);
#define optlightuserdata moonchipmunk_optlightuserdata
void *optlightuserdata(lua_State *L, int arg);
#define testindex moonchipmunk_testindex
int testindex(lua_State *L, int arg, int *err);
#define checkindex moonchipmunk_checkindex
int checkindex(lua_State *L, int arg);
#define optindex moonchipmunk_optindex
int optindex(lua_State *L, int arg, int optval);
#define pushindex moonchipmunk_pushindex
void pushindex(lua_State *L, int val);

/* datastructs.c */
#define isglmathcompat moonchipmunk_isglmathcompat
int isglmathcompat(void);
#define glmathcompat moonchipmunk_glmathcompat
int glmathcompat(lua_State *L, int on);

#define testvec moonchipmunk_testvec
int testvec(lua_State *L, int arg, vec_t *dst);
#define optvec moonchipmunk_optvec
int optvec(lua_State *L, int arg, vec_t *dst);
#define checkvec moonchipmunk_checkvec
int checkvec(lua_State *L, int arg, vec_t *dst);
#define pushvec moonchipmunk_pushvec
void pushvec(lua_State *L, const vec_t *val);
#define checkveclist moonchipmunk_checkveclist
vec_t *checkveclist(lua_State *L, int arg, int *countp, int *err);
#define pushveclist moonchipmunk_pushveclist
void pushveclist(lua_State *L, const vec_t *vecs , int count);

#define testmat moonchipmunk_testmat
int testmat(lua_State *L, int arg, mat_t *dst);
#define optmat moonchipmunk_optmat
int optmat(lua_State *L, int arg, mat_t *dst);
#define checkmat moonchipmunk_checkmat
int checkmat(lua_State *L, int arg, mat_t *dst);
#define checkmatlist moonchipmunk_checkmatlist
//mat_t *checkmatlist(lua_State *L, int arg, int *countp, int *err);
#define pushmat moonchipmunk_pushmat
void pushmat(lua_State *L, mat_t *val);

#define testbb moonchipmunk_testbb
int testbb(lua_State *L, int arg, bb_t *dst);
#define optbb moonchipmunk_optbb
int optbb(lua_State *L, int arg, bb_t *dst);
#define checkbb moonchipmunk_checkbb
int checkbb(lua_State *L, int arg, bb_t *dst);
#define checkbblist moonchipmunk_checkbblist
//bb_t *checkbblist(lua_State *L, int arg, int *countp, int *err);
#define pushbb moonchipmunk_pushbb
void pushbb(lua_State *L, bb_t *val);

#define testcolor moonchipmunk_testcolor
int testcolor(lua_State *L, int arg, color_t *dst);
#define optcolor moonchipmunk_optcolor
int optcolor(lua_State *L, int arg, color_t *dst);
#define checkcolor moonchipmunk_checkcolor
int checkcolor(lua_State *L, int arg, color_t *dst);
#define pushcolor moonchipmunk_pushcolor
void pushcolor(lua_State *L, color_t *val);

#define pushpointqueryinfo moonchipmunk_pushpointqueryinfo
void pushpointqueryinfo(lua_State *L, cpPointQueryInfo *val);
#define pushsegmentqueryinfo moonchipmunk_pushsegmentqueryinfo
void pushsegmentqueryinfo(lua_State *L, cpSegmentQueryInfo *val);
#define checkcontactpointset moonchipmunk_checkcontactpointset
int checkcontactpointset(lua_State *L, int arg, cpContactPointSet *dst);
#define pushcontactpointset moonchipmunk_pushcontactpointset
int pushcontactpointset(lua_State *L, cpContactPointSet *val);
#define checkshapefilter moonchipmunk_checkshapefilter
int checkshapefilter(lua_State *L, int arg, cpShapeFilter *dst);
#define pushshapefilter moonchipmunk_pushshapefilter
void pushshapefilter(lua_State *L, cpShapeFilter *val);

/* Internal error codes */
#define ERR_NOTPRESENT       1
#define ERR_SUCCESS          0
#define ERR_GENERIC         -1
#define ERR_TYPE            -2
#define ERR_ELEMTYPE        -3
#define ERR_VALUE           -4
#define ERR_ELEMVALUE       -5
#define ERR_TABLE           -6
#define ERR_FUNCTION        -7
#define ERR_EMPTY           -8
#define ERR_MEMORY          -9
#define ERR_MALLOC_ZERO     -10
#define ERR_LENGTH          -11
#define ERR_POOL            -12
#define ERR_BOUNDARIES      -13
#define ERR_RANGE           -14
#define ERR_FOPEN           -15
#define ERR_OPERATION       -16
#define ERR_UNKNOWN         -17
#define errstring moonchipmunk_errstring
const char* errstring(int err);

/* tracing.c */
#define trace_objects moonchipmunk_trace_objects
extern int trace_objects;

/* shape.c */
#define shapedestroy moonchipmunk_shapedestroy
int shapedestroy(lua_State *L, shape_t *shape);
#define candestroyshape moonchipmunk_candestroyshape
int candestroyshape(shape_t *shape, ud_t *ud);

/* collision_handler.c */
#define newcollision_handler moonchipmunk_newcollision_handler
int newcollision_handler(lua_State *L, collision_handler_t *handler, space_t *space);

/* constraint.c */
#define constraintdestroy moonchipmunk_constraintdestroy
int constraintdestroy(lua_State *L, constraint_t *constraint);
#define candestroyconstraint moonchipmunk_candestroyconstraint
int candestroyconstraint(constraint_t *constraint, ud_t *ud);

/* body.c */
#define freebody moonchipmunk_freebody
int freebody(lua_State *L, ud_t *ud);
#define newbody moonchipmunk_newbody
int newbody(lua_State *L, body_t *body, int borrowed);

/* main.c */
extern lua_State *moonchipmunk_L;
int luaopen_moonchipmunk(lua_State *L);
void moonchipmunk_open_enums(lua_State *L);
void moonchipmunk_open_flags(lua_State *L);
void moonchipmunk_open_tracing(lua_State *L);
void moonchipmunk_open_misc(lua_State *L);
void moonchipmunk_open_space(lua_State *L);
void moonchipmunk_open_body(lua_State *L);
void moonchipmunk_open_shape(lua_State *L);
void moonchipmunk_open_circle(lua_State *L);
void moonchipmunk_open_segment(lua_State *L);
void moonchipmunk_open_poly(lua_State *L);
void moonchipmunk_open_constraint(lua_State *L);
void moonchipmunk_open_pin_joint(lua_State *L);
void moonchipmunk_open_slide_joint(lua_State *L);
void moonchipmunk_open_pivot_joint(lua_State *L);
void moonchipmunk_open_groove_joint(lua_State *L);
void moonchipmunk_open_damped_spring(lua_State *L);
void moonchipmunk_open_damped_rotary_spring(lua_State *L);
void moonchipmunk_open_rotary_limit_joint(lua_State *L);
void moonchipmunk_open_ratchet_joint(lua_State *L);
void moonchipmunk_open_gear_joint(lua_State *L);
void moonchipmunk_open_simple_motor(lua_State *L);
void moonchipmunk_open_arbiter(lua_State *L);
void moonchipmunk_open_collision_handler(lua_State *L);

/*------------------------------------------------------------------------------*
 | Debug and other utilities                                                    |
 *------------------------------------------------------------------------------*/

/* If this is printed, it denotes a suspect bug: */
#define UNEXPECTED_ERROR "unexpected error (%s, %d)", __FILE__, __LINE__
#define unexpected(L) luaL_error((L), UNEXPECTED_ERROR)

/* Errors with internal error code (ERR_XXX) */
#define failure(L, errcode) luaL_error((L), errstring((errcode)))
#define argerror(L, arg, errcode) luaL_argerror((L), (arg), errstring((errcode)))
#define errmemory(L) luaL_error((L), errstring((ERR_MEMORY)))

#define notsupported(L) luaL_error((L), "operation not supported")
#define badvalue(L, s)   lua_pushfstring((L), "invalid value '%s'", (s))


/* Reference/unreference variables on the Lua registry */
#define Unreference(L, ref) do {                        \
    if((ref)!= LUA_NOREF)                               \
        {                                               \
        luaL_unref((L), LUA_REGISTRYINDEX, (ref));      \
        (ref) = LUA_NOREF;                              \
        }                                               \
} while(0)

#define Reference(L, arg, ref)  do {                    \
    Unreference((L), (ref));                            \
    lua_pushvalue(L, (arg));                            \
    (ref) = luaL_ref(L, LUA_REGISTRYINDEX);             \
} while(0)

/* DEBUG -------------------------------------------------------- */
#if defined(DEBUG)

#define DBG printf
#define TR() do { printf("trace %s %d\n",__FILE__,__LINE__); } while(0)
#define BK() do { printf("break %s %d\n",__FILE__,__LINE__); getchar(); } while(0)
#define TSTART double ts = now();
#define TSTOP do {                                          \
    ts = since(ts); ts = ts*1e6;                            \
    printf("%s %d %.3f us\n", __FILE__, __LINE__, ts);      \
    ts = now();                                             \
} while(0);

#else 

#define DBG noprintf
#define TR()
#define BK()
#define TSTART do {} while(0) 
#define TSTOP do {} while(0)    

#endif /* DEBUG ------------------------------------------------- */

#endif /* internalDEFINED */
