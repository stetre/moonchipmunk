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
 
   
static int MomentForCircle(lua_State *L)
    {
    vec_t offset;
    double m = luaL_checknumber(L, 1);
    double r1 = luaL_checknumber(L, 2);
    double r2 = luaL_checknumber(L, 3);
    checkvec(L, 4, &offset);
    lua_pushnumber(L, cpMomentForCircle(m, r1, r2, offset));
    return 1;
    }

static int AreaForCircle(lua_State *L)
    {
    double r1 = luaL_checknumber(L, 1);
    double r2 = luaL_checknumber(L, 2);
    lua_pushnumber(L, cpAreaForCircle(r1, r2));
    return 1;
    }

static int MomentForSegment(lua_State *L) 
    {
    vec_t a, b;
    double m = luaL_checknumber(L, 1);
    double radius = luaL_checknumber(L, 4);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    lua_pushnumber(L, cpMomentForSegment(m, a, b, radius));
    return 1;
    }

static int AreaForSegment(lua_State *L)
    {
    vec_t a, b;
    double radius = luaL_checknumber(L, 3);
    checkvec(L, 1, &a);
    checkvec(L, 2, &b);
    lua_pushnumber(L, cpAreaForSegment(a, b, radius));
    return 1;
    }

static int MomentForPoly(lua_State *L)
    {
    int count;
    vec_t offset, *verts;
    double m, radius, res;
    m = luaL_checknumber(L, 1);
    checkvec(L, 3, &offset);
    radius = luaL_checknumber(L, 4);
    verts = checkveclist(L, 2, &count, NULL);
    res = cpMomentForPoly(m, count, verts, offset, radius);
    Free(L, verts);
    lua_pushnumber(L, res);
    return 1;
    }

static int AreaForPoly(lua_State *L)
    {
    int count;
    vec_t *verts;
    double radius, res;
    radius = luaL_checknumber(L, 2);
    verts = checkveclist(L, 1, &count, NULL);
    res = cpAreaForPoly(count, verts, radius);
    Free(L, verts);
    lua_pushnumber(L, res);
    return 1;
    }

static int CentroidForPoly(lua_State *L)
    {
    int count;
    vec_t *verts, v;
    verts = checkveclist(L, 1, &count, NULL);
    v = cpCentroidForPoly(count, verts);
    Free(L, verts);
    pushvec(L, &v);
    return 1;
    }

static int MomentForBox(lua_State *L)
    {
    bb_t box;
    double width, height;
    double m = luaL_checknumber(L, 1);
    if(lua_isnumber(L, 2))
        {
        width = luaL_checknumber(L, 2);
        height = luaL_checknumber(L, 3);
        lua_pushnumber(L, cpMomentForBox(m, width, height));
        }
    else
        {
        checkbb(L, 2, &box);
        lua_pushnumber(L, cpMomentForBox2(m, box));
        }
    return 1;
    }

static int ConvexHull(lua_State *L)
    {
    int count, hcount;
    double tol = luaL_checknumber(L, 2);
    vec_t *verts = checkveclist(L, 1, &count, NULL);
    hcount = cpConvexHull(count, verts, verts, NULL, tol);
    pushveclist(L, verts, hcount);
    Free(L, verts);
    return 1;
    }

/*------------------------------------------------------------------------------*
 | cpfxxx() functions                                                           |
 *------------------------------------------------------------------------------*/

static int Fclamp(lua_State *L)
    {
    double f = luaL_checknumber(L, 1);
    double a = luaL_checknumber(L, 2);
    double b = luaL_checknumber(L, 3);
    lua_pushnumber(L, cpfclamp(f, a, b));
    return 1;
    }

static int Fclamp01(lua_State *L)
    {
    double f = luaL_checknumber(L, 1);
    lua_pushnumber(L, cpfclamp01(f));
    return 1;
    }

static int Flerp(lua_State *L)
    {
    double f1 = luaL_checknumber(L, 1);
    double f2 = luaL_checknumber(L, 2);
    double f = luaL_checknumber(L, 3);
    lua_pushnumber(L, cpflerp(f1, f2, f));
    return 1;
    }

static int Flerpconst(lua_State *L)
    {
    double f1 = luaL_checknumber(L, 1);
    double f2 = luaL_checknumber(L, 2);
    double d = luaL_checknumber(L, 3);
    lua_pushnumber(L, cpflerpconst(f1, f2, d));
    return 1;
    }

/*------------------------------------------------------------------------------*
 | vec_t functions (cpvxxx())                                                   |
 *------------------------------------------------------------------------------*/

static int Veql(lua_State *L)
    {
    vec_t v1, v2;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    lua_pushboolean(L, cpveql(v1, v2));
    return 1;
    }

static int Vadd(lua_State *L)
    {
    vec_t v1, v2, v;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    v = cpvadd(v1, v2);
    pushvec(L, &v);
    return 1;
    }

static int Vsub(lua_State *L)
    {
    vec_t v1, v2, v;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    v = cpvsub(v1, v2);
    pushvec(L, &v);
    return 1;
    }

static int Vneg(lua_State *L)
    {
    vec_t v1, v;
    checkvec(L, 1, &v1);
    v = cpvneg(v1);
    pushvec(L, &v);
    return 1;
    }

static int Vmult(lua_State *L)
    {
    vec_t v1, v;
    double s;
    checkvec(L, 1, &v1);
    s = luaL_checknumber(L, 2);
    v = cpvmult(v1, s);
    pushvec(L, &v);
    return 1;
    }

static int Vdot(lua_State *L)
    {
    vec_t v1, v2;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    lua_pushnumber(L, cpvdot(v1, v2));
    return 1;
    }

static int Vcross(lua_State *L)
    {
    vec_t v1, v2;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    lua_pushnumber(L, cpvcross(v1, v2));
    return 1;
    }

static int Vperp(lua_State *L)
    {
    vec_t v1, v;
    checkvec(L, 1, &v1);
    v = cpvperp(v1);
    pushvec(L, &v);
    return 1;
    }

static int Vrperp(lua_State *L)
    {
    vec_t v1, v;
    checkvec(L, 1, &v1);
    v = cpvrperp(v1);
    pushvec(L, &v);
    return 1;
    }

static int Vproject(lua_State *L)
    {
    vec_t v1, v2, v;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    v = cpvproject(v1, v2);
    pushvec(L, &v);
    return 1;
    }

static int Vforangle(lua_State *L)
    {
    vec_t v;
    double a = luaL_checknumber(L, 1);
    v = cpvforangle(a);
    pushvec(L, &v);
    return 1;
    }

static int Vtoangle(lua_State *L)
    {
    vec_t v;
    checkvec(L, 1, &v);
    lua_pushnumber(L, cpvtoangle(v));
    return 1;
    }

static int Vrotate(lua_State *L)
    {
    vec_t v1, v2, v;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    v = cpvrotate(v1, v2);
    pushvec(L, &v);
    return 1;
    }

static int Vunrotate(lua_State *L)
    {
    vec_t v1, v2, v;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    v = cpvunrotate(v1, v2);
    pushvec(L, &v);
    return 1;
    }

static int Vlengthsq(lua_State *L)
    {
    vec_t v;
    checkvec(L, 1, &v);
    lua_pushnumber(L, cpvlengthsq(v));
    return 1;
    }

static int Vlength(lua_State *L)
    {
    vec_t v;
    checkvec(L, 1, &v);
    lua_pushnumber(L, cpvlength(v));
    return 1;
    }

static int Vlerp(lua_State *L)
    {
    vec_t v1, v2, v;
    double t;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    t = luaL_checknumber(L, 3);
    v = cpvlerp(v1, v2, t);
    pushvec(L, &v);
    return 1;
    }

static int Vnormalize(lua_State *L)
    {
    vec_t v;
    checkvec(L, 1, &v);
    v = cpvnormalize(v);
    pushvec(L, &v);
    return 1;
    }

static int Vslerp(lua_State *L)
    {
    vec_t v1, v2, v;
    double t;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    t = luaL_checknumber(L, 3);
    v = cpvslerp(v1, v2, t);
    pushvec(L, &v);
    return 1;
    }

static int Vslerpconst(lua_State *L)
    {
    vec_t v1, v2, v;
    double t;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    t = luaL_checknumber(L, 3);
    v = cpvslerpconst(v1, v2, t);
    pushvec(L, &v);
    return 1;
    }

static int Vclamp(lua_State *L)
    {
    vec_t v;
    double len;
    checkvec(L, 1, &v);
    len = luaL_checknumber(L, 2);
    v = cpvclamp(v, len);
    pushvec(L, &v);
    return 1;
    }

static int Vlerpconst(lua_State *L)
    {
    vec_t v1, v2, v;
    double d;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    d = luaL_checknumber(L, 3);
    v = cpvlerpconst(v1, v2, d);
    pushvec(L, &v);
    return 1;
    }

static int Vdist(lua_State *L)
    {
    vec_t v1, v2;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    lua_pushnumber(L, cpvdist(v1, v2));
    return 1;
    }

static int Vdistsq(lua_State *L)
    {
    vec_t v1, v2;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    lua_pushnumber(L, cpvdistsq(v1, v2));
    return 1;
    }

static int Vnear(lua_State *L)
    {
    vec_t v1, v2;
    double d;
    checkvec(L, 1, &v1);
    checkvec(L, 2, &v2);
    d = luaL_checknumber(L, 3);
    lua_pushboolean(L, cpvnear(v1, v2, d));
    return 1;
    }

static int ClosestPointOnSegment(lua_State *L)
    {
    vec_t p, a, b;
    checkvec(L, 1, &p);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    p = cpClosetPointOnSegment(p, a, b);
    pushvec(L, &p);
    return 1;
    }

static int CheckPointGreater(lua_State *L)
    {
    vec_t a, b, c;
    checkvec(L, 1, &c);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    lua_pushboolean(L, cpCheckPointGreater(a, b, c));
    return 1;
    }

static int CheckAxis(lua_State *L)
    {
    vec_t v0, v1, p, n;
    checkvec(L, 1, &v0);
    checkvec(L, 2, &v1);
    checkvec(L, 3, &p);
    checkvec(L, 4, &n);
    lua_pushboolean(L, cpCheckAxis(v0, v1, p, n));
    return 1;
    }

/*------------------------------------------------------------------------------*
 | mat_t functions (cpTransformXxx())                                           |
 *------------------------------------------------------------------------------*/

static int TransformIdentity (lua_State *L)
    {
    pushmat(L, (mat_t*)&cpTransformIdentity);
    return 1;
    }

static int TransformNew(lua_State *L)
    {
    double a = luaL_checknumber(L, 1);
    double b = luaL_checknumber(L, 2);
    double c = luaL_checknumber(L, 3);
    double d = luaL_checknumber(L, 4);
    double tx = luaL_checknumber(L, 5);
    double ty = luaL_checknumber(L, 6);
    mat_t m = cpTransformNew(a, b, c, d, tx, ty);
    pushmat(L, &m);
    return 1;
    }

static int TransformNewTranspose(lua_State *L)
    {
    double a = luaL_checknumber(L, 1);
    double c = luaL_checknumber(L, 2);
    double tx = luaL_checknumber(L, 3);
    double b = luaL_checknumber(L, 4);
    double d = luaL_checknumber(L, 5);
    double ty = luaL_checknumber(L, 6);
    mat_t m = cpTransformNewTranspose(a, c, tx, b, d, ty);
    pushmat(L, &m);
    return 1;
    }

static int TransformInverse(lua_State *L)
    {
    mat_t m;
    checkmat(L, 1, &m);
    m = cpTransformInverse(m);
    pushmat(L, &m);
    return 1;
    }

static int TransformMult(lua_State *L)
    {
    mat_t m1, m2, m;
    checkmat(L, 1, &m1);
    checkmat(L, 2, &m2);
    m = cpTransformMult(m1, m2);
    pushmat(L, &m);
    return 1;
    }

static int TransformPoint(lua_State *L)
    {
    mat_t m;
    vec_t p;
    checkmat(L, 1, &m);
    checkvec(L, 2, &p);
    p = cpTransformPoint(m, p);
    pushvec(L, &p);
    return 1;
    }

static int TransformVect(lua_State *L)
    {
    mat_t m;
    vec_t v;
    checkmat(L, 1, &m);
    checkvec(L, 2, &v);
    v = cpTransformVect(m, v);
    pushvec(L, &v);
    return 1;
    }

static int TransformbBB(lua_State *L)
    {
    bb_t bb, r;
    mat_t t;
    checkmat(L, 1, &t);
    checkbb(L, 2, &bb);
    r = cpTransformbBB(t, bb);
    pushbb(L, &r);
    return 1;
    }

static int TransformTranslate(lua_State *L)
    {
    mat_t r;
    vec_t v;
    checkvec(L, 1, &v);
    r = cpTransformTranslate(v);
    pushmat(L, &r);
    return 1;
    }

static int TransformScale(lua_State *L)
    {
    mat_t r;
    double sx = luaL_checknumber(L, 1);
    double sy = luaL_checknumber(L, 2);
    r = cpTransformScale(sx, sy);
    pushmat(L, &r);
    return 1;
    }

static int TransformRotate(lua_State *L)
    {
    mat_t r;
    double radians = luaL_checknumber(L, 1);
    r = cpTransformRotate(radians);
    pushmat(L, &r);
    return 1;
    }

static int TransformRigid(lua_State *L)
    {
    mat_t r;
    vec_t translate;
    double radians;
    checkvec(L, 1, &translate);
    radians = luaL_checknumber(L, 2);
    r = cpTransformRigid(translate, radians);
    pushmat(L, &r);
    return 1;
    }

static int TransformRigidInverse(lua_State *L)
    {
    mat_t r, t;
    checkmat(L, 1, &t);
    r = cpTransformRigidInverse(t);
    pushmat(L, &r);
    return 1;
    }

static int TransformWrap(lua_State *L)
    {
    mat_t r, inner, outer;
    checkmat(L, 1, &outer);
    checkmat(L, 2, &inner);
    r = cpTransformWrap(outer, inner);
    pushmat(L, &r);
    return 1;
    }

static int TransformWrapInverse(lua_State *L)
    {
    mat_t r, inner, outer;
    checkmat(L, 1, &outer);
    checkmat(L, 2, &inner);
    r = cpTransformWrapInverse(outer, inner);
    pushmat(L, &r);
    return 1;
    }

static int TransformOrtho(lua_State *L)
    {
    mat_t r;
    bb_t bb;
    checkbb(L, 1, &bb);
    r = cpTransformOrtho(bb);
    pushmat(L, &r);
    return 1;
    }

static int TransformBoneScale(lua_State *L)
    {
    mat_t r;
    vec_t v0, v1;
    checkvec(L, 1, &v0);
    checkvec(L, 2, &v1);
    r = cpTransformBoneScale(v0, v1);
    pushmat(L, &r);
    return 1;
    }

static int TransformAxialScale(lua_State *L)
    {
    mat_t r;
    vec_t axis, pivot;
    double scale;
    checkvec(L, 1, &axis);
    checkvec(L, 2, &pivot);
    scale = luaL_checknumber(L, 3);
    r = cpTransformAxialScale(axis, pivot, scale);
    pushmat(L, &r);
    return 1;
    }


/*------------------------------------------------------------------------------*
 | bb_t functions (cpBBXxx()                                                    |
 *------------------------------------------------------------------------------*/

static int BBNewForExtents(lua_State *L)
    {
    bb_t b;
    vec_t c;
    double hw, hh;
    checkvec(L, 1, &c);
    hw = luaL_checknumber(L, 2);
    hh = luaL_checknumber(L, 3);
    b = cpBBNewForExtents(c, hw, hh);
    pushbb(L, &b);
    return 1;
    }

static int BBNewForCircle(lua_State *L)
    {
    bb_t b;
    vec_t c;
    double r;
    checkvec(L, 1, &c);
    r = luaL_checknumber(L, 2);
    b = cpBBNewForCircle(c, r);
    pushbb(L, &b);
    return 1;
    }

static int BBIntersects(lua_State *L)
    {
    bb_t a, b;
    checkbb(L, 1, &a);
    checkbb(L, 2, &b);
    lua_pushboolean(L, cpBBIntersects(a, b));
    return 1;
    }

static int BBContainsBB(lua_State *L)
    {
    bb_t a, b;
    checkbb(L, 1, &a);
    checkbb(L, 2, &b);
    lua_pushboolean(L, cpBBContainsBB(a, b));
    return 1;
    }

static int BBContainsVect(lua_State *L)
    {
    bb_t b;
    vec_t v;
    checkbb(L, 1, &b);
    checkvec(L, 2, &v);
    lua_pushboolean(L, cpBBContainsVect(b, v));
    return 1;
    }

static int BBMerge(lua_State *L)
    {
    bb_t a, b, c;
    checkbb(L, 1, &a);
    checkbb(L, 2, &b);
    c = cpBBMerge(a, b);
    pushbb(L, &c);
    return 1;
    }

static int BBExpand(lua_State *L)
    {
    bb_t b, c;
    vec_t v;
    checkbb(L, 1, &b);
    checkvec(L, 2, &v);
    c = cpBBExpand(b, v);
    pushbb(L, &c);
    return 1;
    }

static int BBCenter(lua_State *L)
    {
    bb_t b;
    vec_t v;
    checkbb(L, 1, &b);
    v = cpBBCenter(b);
    pushvec(L, &v);
    return 1;
    }

static int BBArea(lua_State *L)
    {
    bb_t b;
    checkbb(L, 1, &b);
    lua_pushnumber(L, cpBBArea(b));
    return 1;
    }

static int BBMergedArea(lua_State *L)
    {
    bb_t a, b;
    checkbb(L, 1, &a);
    checkbb(L, 2, &b);
    lua_pushnumber(L, cpBBMergedArea(a, b));
    return 1;
    }

static int BBSegmentQuery(lua_State *L)
    {
    bb_t bb;
    vec_t a, b;
    checkbb(L, 1, &bb);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    lua_pushnumber(L, cpBBSegmentQuery(bb, a, b));
    return 1;
    }

static int BBIntersectsSegment(lua_State *L)
    {
    bb_t bb;
    vec_t a, b;
    checkbb(L, 1, &bb);
    checkvec(L, 2, &a);
    checkvec(L, 3, &b);
    lua_pushboolean(L, cpBBIntersectsSegment(bb, a, b));
    return 1;
    }

static int BBClampVect(lua_State *L)
    {
    bb_t b;
    vec_t v, r;
    checkbb(L, 1, &b);
    checkvec(L, 2, &v);
    r = cpBBClampVect(b, v);
    pushvec(L, &r);
    return 1;
    }

static int BBWrapVect(lua_State *L)
    {
    bb_t b;
    vec_t v, r;
    checkbb(L, 1, &b);
    checkvec(L, 2, &v);
    r = cpBBWrapVect(b, v);
    pushvec(L, &r);
    return 1;
    }

static int BBOffset(lua_State *L)
    {
    bb_t b, r;
    vec_t v;
    checkbb(L, 1, &b);
    checkvec(L, 2, &v);
    r = cpBBOffset(b, v);
    pushbb(L, &r);
    return 1;
    }

/*------------------------------------------------------------------------------*
 | cpMarchXxx()                                                                 |
 *------------------------------------------------------------------------------*/

static int ref_sample = LUA_NOREF;
static int ref_segment = LUA_NOREF;

static double MarchSampleFunc(vec_t point, void *data)
    {
    double density;
    lua_State *L = moonchipmunk_L;
    int top = lua_gettop(L);
    (void)data;
    lua_rawgeti(L, LUA_REGISTRYINDEX, ref_sample);
    pushvec(L, &point);
    if(lua_pcall(L, 1, 1, 0)!=LUA_OK)
        { lua_error(L); return 0.0f; }
    density = lua_tonumber(L, -1);
    lua_settop(L, top);
    return density;
    }

static void MarchSegmentFunc(vec_t v0, vec_t v1, void *data)
    {
    lua_State *L = moonchipmunk_L;
    int top = lua_gettop(L);
    (void)data;
    lua_rawgeti(L, LUA_REGISTRYINDEX, ref_segment);
    pushvec(L, &v0);
    pushvec(L, &v1);
    if(lua_pcall(L, 2, 0, 0)!=LUA_OK)
        { lua_error(L); return; }
    lua_settop(L, top);
    return;
    }

#define F(Func, func)                                               \
static int Func(lua_State *L)                                       \
    {                                                               \
    bb_t bb;                                                        \
    unsigned long x_samples, y_samples;                             \
    double threshold;                                               \
    checkbb(L, 1, &bb);                                             \
    x_samples = luaL_checkinteger(L, 2);                            \
    y_samples = luaL_checkinteger(L, 3);                            \
    threshold = luaL_checknumber(L, 4);                             \
    if(!lua_isfunction(L, 5)) return argerror(L, 5, ERR_FUNCTION);  \
    if(!lua_isfunction(L, 6)) return argerror(L, 6, ERR_FUNCTION);  \
    Reference(L, 5, ref_sample);                                    \
    Reference(L, 6, ref_segment);                                   \
    func(bb, x_samples, y_samples, threshold, MarchSegmentFunc, NULL, MarchSampleFunc, NULL);   \
    Unreference(L, ref_sample);                                     \
    Unreference(L, ref_segment);                                    \
    return 0;                                                       \
    }
F(MarchSoft, cpMarchSoft)
F(MarchHard, cpMarchHard)
#undef F

static const struct luaL_Reg Functions[] = 
    {
        { "moment_for_circle", MomentForCircle },
        { "area_for_circle", AreaForCircle },
        { "moment_for_segment", MomentForSegment },
        { "area_for_segment", AreaForSegment },
        { "moment_for_poly", MomentForPoly },
        { "area_for_poly", AreaForPoly },
        { "centroid_for_poly", CentroidForPoly },
        { "moment_for_box", MomentForBox },
        { "convex_hull", ConvexHull },
        //----- cpfxxx() -----------------------------------------------
        { "fclamp", Fclamp },
        { "fclamp01", Fclamp01 },
        { "flerp", Flerp },
        { "flerpconst", Flerpconst },
        //----- cpvxxx() ---------------------------------------
        { "veql", Veql },
        { "vadd", Vadd },
        { "vsub", Vsub },
        { "vneg", Vneg },
        { "vmult", Vmult },
        { "vdot", Vdot },
        { "vcross", Vcross },
        { "vperp", Vperp },
        { "vrperp", Vrperp },
        { "vproject", Vproject },
        { "vforangle", Vforangle },
        { "vtoangle", Vtoangle },
        { "vrotate", Vrotate },
        { "vunrotate", Vunrotate },
        { "vlengthsq", Vlengthsq },
        { "vlength", Vlength },
        { "vlerp", Vlerp },
        { "vnormalize", Vnormalize },
        { "vslerp", Vslerp },
        { "vslerpconst", Vslerpconst },
        { "vclamp", Vclamp },
        { "vlerpconst", Vlerpconst },
        { "vdist", Vdist },
        { "vdistsq", Vdistsq },
        { "vnear", Vnear },
        { "closest_point_on_segment", ClosestPointOnSegment },
        { "check_point_greater", CheckPointGreater },
        { "check_axis", CheckAxis },
        //----- cpTransformXxx() ---------------------------------------
        { "transform_identity", TransformIdentity },
        { "transform_new", TransformNew },
        { "transform_new_transpose", TransformNewTranspose },
        { "transform_inverse", TransformInverse },
        { "transform_mult", TransformMult },
        { "transform_point", TransformPoint },
        { "transform_vect", TransformVect },
        { "transform_bb", TransformbBB },
        { "transform_translate", TransformTranslate },
        { "transform_scale", TransformScale },
        { "transform_rotate", TransformRotate },
        { "transform_rigid", TransformRigid },
        { "transform_rigid_inverse", TransformRigidInverse },
        { "transform_wrap", TransformWrap },
        { "transform_wrap_inverse", TransformWrapInverse },
        { "transform_ortho", TransformOrtho },
        { "transform_bone_scale", TransformBoneScale },
        { "transform_axial_scale", TransformAxialScale },
        //----- cpBBXxx() ----------------------------------------------
        { "bb_new_for_extents", BBNewForExtents },
        { "bb_new_for_circle", BBNewForCircle },
        { "bb_intersects", BBIntersects },
        { "bb_contains_bb", BBContainsBB },
        { "bb_contains_vect", BBContainsVect },
        { "bb_merge", BBMerge },
        { "bb_expand", BBExpand },
        { "bb_center", BBCenter },
        { "bb_area", BBArea },
        { "bb_merged_area", BBMergedArea },
        { "bb_segment_query", BBSegmentQuery },
        { "bb_intersects_segment", BBIntersectsSegment },
        { "bb_clamp_vect", BBClampVect },
        { "bb_wrap_vect", BBWrapVect },
        { "bb_offset", BBOffset },
        //----- cpMarchXxx() -------------------------------------------
        { "march_soft", MarchSoft },
        { "march_hard", MarchHard },
        { NULL, NULL } /* sentinel */
    };

void moonchipmunk_open_misc(lua_State *L)
    {
    luaL_setfuncs(L, Functions, 0);
    }

