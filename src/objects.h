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

#ifndef objectsDEFINED
#define objectsDEFINED

#include "tree.h"
#include "udata.h"

/* Chipmunk renaming (for internal use) */
#define vec_t cpVect
#define mat_t cpTransform
#define bb_t cpBB
#define space_t cpSpace
#define body_t cpBody
#define shape_t cpShape
#define constraint_t cpConstraint
#define arbiter_t cpArbiter
#define collision_handler_t cpCollisionHandler
#define color_t cpSpaceDebugColor

/* Objects' metatable names */
#define SPACE_MT "moonchipmunk_space"
#define BODY_MT "moonchipmunk_body"
#define SHAPE_MT "moonchipmunk_shape"
#define CIRCLE_MT "moonchipmunk_circle"     /* shape */
#define SEGMENT_MT "moonchipmunk_segment"   /* shape */
#define POLY_MT "moonchipmunk_poly"         /* shape */
#define CONSTRAINT_MT "moonchipmunk_constraint"
#define PIN_JOINT_MT "moonchipmunk_pin_joint"                       /* constraint */
#define SLIDE_JOINT_MT "moonchipmunk_slide_joint"                   /* constraint */
#define PIVOT_JOINT_MT "moonchipmunk_pivot_joint"                   /* constraint */
#define GROOVE_JOINT_MT "moonchipmunk_groove_joint"                 /* constraint */
#define DAMPED_SPRING_MT "moonchipmunk_damped_spring"               /* constraint */
#define DAMPED_ROTARY_SPRING_MT "moonchipmunk_damped_rotary_spring" /* constraint */
#define ROTARY_LIMIT_JOINT_MT "moonchipmunk_rotary_limit_joint"     /* constraint */
#define RATCHET_JOINT_MT "moonchipmunk_ratchet_joint"               /* constraint */
#define GEAR_JOINT_MT "moonchipmunk_gear_joint"                     /* constraint */
#define SIMPLE_MOTOR_MT "moonchipmunk_simple_motor"                 /* constraint */
#define ARBITER_MT "moonchipmunk_arbiter"
#define COLLISION_HANDLER_MT "moonchipmunk_collision_handler"

/* Userdata memory associated with objects */
#define ud_t moonchipmunk_ud_t
typedef struct moonchipmunk_ud_s ud_t;

struct moonchipmunk_ud_s {
    void *handle; /* the object handle bound to this userdata */
    int (*destructor)(lua_State *L, ud_t *ud);  /* self destructor */
    ud_t *parent_ud; /* the ud of the parent object */
    uint32_t marks;
    int ref1, ref2, ref3, ref4; /* refs for callbacks, automatically unreferenced at destruction */
    body_t *static_body;
    void *info; /* object specific info (ud_info_t, subject to Free() at destruction, if not NULL) */
};
    
/* Marks.  m_ = marks word (uint32_t) , i_ = bit number (0 .. 31)  */
#define MarkGet(m_,i_)  (((m_) & ((uint32_t)1<<(i_))) == ((uint32_t)1<<(i_)))
#define MarkSet(m_,i_)  do { (m_) = ((m_) | ((uint32_t)1<<(i_))); } while(0)
#define MarkReset(m_,i_) do { (m_) = ((m_) & (~((uint32_t)1<<(i_)))); } while(0)

#define IsValid(ud)             MarkGet((ud)->marks, 0)
#define MarkValid(ud)           MarkSet((ud)->marks, 0) 
#define CancelValid(ud)         MarkReset((ud)->marks, 0)

#define IsBorrowed(ud)          MarkGet((ud)->marks, 1)
#define MarkBorrowed(ud)        MarkSet((ud)->marks, 1) 
#define CancelBorrowed(ud)      MarkReset((ud)->marks, 1)

#define IsHasty(ud)             MarkGet((ud)->marks, 2)
#define MarkHasty(ud)           MarkSet((ud)->marks, 2)
#define CancelHasty(ud)         MarkReset((ud)->marks, 2)

#if 0
/* .c */
#define  moonchipmunk_
#endif

#define setmetatable moonchipmunk_setmetatable
int setmetatable(lua_State *L, const char *mt);

#define newuserdata moonchipmunk_newuserdata
ud_t *newuserdata(lua_State *L, void *handle, const char *mt, const char *tracename);
#define freeuserdata moonchipmunk_freeuserdata
int freeuserdata(lua_State *L, ud_t *ud, const char *tracename);
#define pushuserdata moonchipmunk_pushuserdata 
int pushuserdata(lua_State *L, ud_t *ud);

#define freechildren moonchipmunk_freechildren
int freechildren(lua_State *L,  const char *mt, ud_t *parent_ud);

#define userdata_unref(L, handle) udata_unref((L),(handle))

#define UD(handle) userdata((handle)) /* dispatchable objects only */
#define userdata moonchipmunk_userdata
ud_t *userdata(const void *handle);
#define testxxx moonchipmunk_testxxx
void *testxxx(lua_State *L, int arg, ud_t **udp, const char *mt);
#define checkxxx moonchipmunk_checkxxx
void *checkxxx(lua_State *L, int arg, ud_t **udp, const char *mt);
#define optxxx moonchipmunk_optxxx
void *optxxx(lua_State *L, int arg, ud_t **udp, const char *mt);
#define pushxxx moonchipmunk_pushxxx
int pushxxx(lua_State *L, void *handle);
#define checkxxxlist moonchipmunk_checkxxxlist
void** checkxxxlist(lua_State *L, int arg, int *count, int *err, const char *mt);

#if 0 // 7yy
/* zzz.c */
#define checkzzz(L, arg, udp) (zzz_t*)checkxxx((L), (arg), (udp), ZZZ_MT)
#define testzzz(L, arg, udp) (zzz_t*)testxxx((L), (arg), (udp), ZZZ_MT)
#define optzzz(L, arg, udp) (zzz_t*)optxxx((L), (arg), (udp), ZZZ_MT)
#define pushzzz(L, handle) pushxxx((L), (void*)(handle))
#define checkzzzlist(L, arg, count, err) checkxxxlist((L), (arg), (count), (err), ZZZ_MT)

#endif

/* space.c */
#define checkspace(L, arg, udp) (space_t*)checkxxx((L), (arg), (udp), SPACE_MT)
#define testspace(L, arg, udp) (space_t*)testxxx((L), (arg), (udp), SPACE_MT)
#define optspace(L, arg, udp) (space_t*)optxxx((L), (arg), (udp), SPACE_MT)
#define pushspace(L, handle) pushxxx((L), (void*)(handle))

/* body.c */
#define checkbody(L, arg, udp) (body_t*)checkxxx((L), (arg), (udp), BODY_MT)
#define testbody(L, arg, udp) (body_t*)testxxx((L), (arg), (udp), BODY_MT)
#define optbody(L, arg, udp) (body_t*)optxxx((L), (arg), (udp), BODY_MT)
#define pushbody(L, handle) pushxxx((L), (void*)(handle))

/* shape.c */
#define checkshape(L, arg, udp) (shape_t*)checkxxx((L), (arg), (udp), SHAPE_MT)
#define testshape(L, arg, udp) (shape_t*)testxxx((L), (arg), (udp), SHAPE_MT)
#define optshape(L, arg, udp) (shape_t*)optxxx((L), (arg), (udp), SHAPE_MT)
#define pushshape(L, handle) pushxxx((L), (void*)(handle))

/* circle.c */
#define checkcircle(L, arg, udp) (shape_t*)checkxxx((L), (arg), (udp), CIRCLE_MT)
#define testcircle(L, arg, udp) (shape_t*)testxxx((L), (arg), (udp), CIRCLE_MT)
#define optcircle(L, arg, udp) (shape_t*)optxxx((L), (arg), (udp), CIRCLE_MT)
#define pushcircle(L, handle) pushxxx((L), (void*)(handle))

/* segment.c */
#define checksegment(L, arg, udp) (shape_t*)checkxxx((L), (arg), (udp), SEGMENT_MT)
#define testsegment(L, arg, udp) (shape_t*)testxxx((L), (arg), (udp), SEGMENT_MT)
#define optsegment(L, arg, udp) (shape_t*)optxxx((L), (arg), (udp), SEGMENT_MT)
#define pushsegment(L, handle) pushxxx((L), (void*)(handle))

/* poly.c */
#define checkpoly(L, arg, udp) (shape_t*)checkxxx((L), (arg), (udp), POLY_MT)
#define testpoly(L, arg, udp) (shape_t*)testxxx((L), (arg), (udp), POLY_MT)
#define optpoly(L, arg, udp) (shape_t*)optxxx((L), (arg), (udp), POLY_MT)
#define pushpoly(L, handle) pushxxx((L), (void*)(handle))

/* constraint.c */
#define checkconstraint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), CONSTRAINT_MT)
#define testconstraint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), CONSTRAINT_MT)
#define optconstraint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), CONSTRAINT_MT)
#define pushconstraint(L, handle) pushxxx((L), (void*)(handle))

/* pin_joint.c */
#define checkpin_joint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), PIN_JOINT_MT)
#define testpin_joint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), PIN_JOINT_MT)
#define optpin_joint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), PIN_JOINT_MT)
#define pushpin_joint(L, handle) pushxxx((L), (void*)(handle))

/* slide_joint.c */
#define checkslide_joint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), SLIDE_JOINT_MT)
#define testslide_joint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), SLIDE_JOINT_MT)
#define optslide_joint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), SLIDE_JOINT_MT)
#define pushslide_joint(L, handle) pushxxx((L), (void*)(handle))

/* pivot_joint.c */
#define checkpivot_joint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), PIVOT_JOINT_MT)
#define testpivot_joint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), PIVOT_JOINT_MT)
#define optpivot_joint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), PIVOT_JOINT_MT)
#define pushpivot_joint(L, handle) pushxxx((L), (void*)(handle))

/* groove_joint.c */
#define checkgroove_joint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), GROOVE_JOINT_MT)
#define testgroove_joint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), GROOVE_JOINT_MT)
#define optgroove_joint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), GROOVE_JOINT_MT)
#define pushgroove_joint(L, handle) pushxxx((L), (void*)(handle))

/* damped_spring.c */
#define checkdamped_spring(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), DAMPED_SPRING_MT)
#define testdamped_spring(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), DAMPED_SPRING_MT)
#define optdamped_spring(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), DAMPED_SPRING_MT)
#define pushdamped_spring(L, handle) pushxxx((L), (void*)(handle))

/* damped_rotary_spring.c */
#define checkdamped_rotary_spring(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), DAMPED_ROTARY_SPRING_MT)
#define testdamped_rotary_spring(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), DAMPED_ROTARY_SPRING_MT)
#define optdamped_rotary_spring(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), DAMPED_ROTARY_SPRING_MT)
#define pushdamped_rotary_spring(L, handle) pushxxx((L), (void*)(handle))

/* rotary_limit_joint.c */
#define checkrotary_limit_joint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), ROTARY_LIMIT_JOINT_MT)
#define testrotary_limit_joint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), ROTARY_LIMIT_JOINT_MT)
#define optrotary_limit_joint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), ROTARY_LIMIT_JOINT_MT)
#define pushrotary_limit_joint(L, handle) pushxxx((L), (void*)(handle))

/* ratchet_joint.c */
#define checkratchet_joint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), RATCHET_JOINT_MT)
#define testratchet_joint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), RATCHET_JOINT_MT)
#define optratchet_joint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), RATCHET_JOINT_MT)
#define pushratchet_joint(L, handle) pushxxx((L), (void*)(handle))

/* gear_joint.c */
#define checkgear_joint(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), GEAR_JOINT_MT)
#define testgear_joint(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), GEAR_JOINT_MT)
#define optgear_joint(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), GEAR_JOINT_MT)
#define pushgear_joint(L, handle) pushxxx((L), (void*)(handle))

/* simple_motor.c */
#define checksimple_motor(L, arg, udp) (constraint_t*)checkxxx((L), (arg), (udp), SIMPLE_MOTOR_MT)
#define testsimple_motor(L, arg, udp) (constraint_t*)testxxx((L), (arg), (udp), SIMPLE_MOTOR_MT)
#define optsimple_motor(L, arg, udp) (constraint_t*)optxxx((L), (arg), (udp), SIMPLE_MOTOR_MT)
#define pushsimple_motor(L, handle) pushxxx((L), (void*)(handle))

/* arbiter.c */
#define pusharbiter moonchipmunk_pusharbiter
int pusharbiter(lua_State *L, arbiter_t *arbiter);
#define invalidatearbiter moonchipmunk_invalidatearbiter
void invalidatearbiter(lua_State *L, arbiter_t *arbiter);
#define testarbiter(L, arg, udp) testxxx((L), (arg), (udp), ARBITER_MT)

/* collision_handler.c */
#define checkcollision_handler(L, arg, udp) (collision_handler_t*)checkxxx((L), (arg), (udp), COLLISION_HANDLER_MT)
#define testcollision_handler(L, arg, udp) (collision_handler_t*)testxxx((L), (arg), (udp), COLLISION_HANDLER_MT)
#define optcollision_handler(L, arg, udp) (collision_handler_t*)optxxx((L), (arg), (udp), COLLISION_HANDLER_MT)
#define pushcollision_handler(L, handle) pushxxx((L), (void*)(handle))

#define RAW_FUNC(xxx)                       \
static int Raw(lua_State *L)                \
    {                                       \
    lua_pushinteger(L, (uintptr_t)check##xxx(L, 1, NULL));  \
    return 1;                               \
    }

#define TYPE_FUNC(xxx) /* NONCL */          \
static int Type(lua_State *L)               \
    {                                       \
    (void)check##xxx(L, 1, NULL);           \
    lua_pushstring(L, ""#xxx);              \
    return 1;                               \
    }

#define DESTROY_FUNC(xxx)                   \
static int Destroy(lua_State *L)            \
    {                                       \
    ud_t *ud;                               \
    (void)test##xxx(L, 1, &ud);             \
    if(!ud) return 0; /* already deleted */ \
    return ud->destructor(L, ud);           \
    }

#define PARENT_FUNC(xxx)                    \
static int Parent(lua_State *L)             \
    {                                       \
    ud_t *ud;                               \
    (void)check##xxx(L, 1, &ud);            \
    if(!ud->parent_ud) return 0;            \
    return pushuserdata(L, ud->parent_ud);  \
    }

#endif /* objectsDEFINED */
