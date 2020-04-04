-------------------------------------------------------------------------------
-- MoonChipmunk Toolbox - tools used in examples and demos
-------------------------------------------------------------------------------

local function optrequire(what)
   local ok, t = pcall(require, what)
   if not ok then return nil end
   return t
end

local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local mi = optrequire("moonimage")
local ft = optrequire("moonfreetype")
local sf = optrequire("moonsndfile")
local al = optrequire("moonal")

local translate, rotate, scale = glmath.translate, glmath.rotate, glmath.scale
local look_at, ortho = glmath.look_at, glmath.ortho
local vec2, vec3, vec4 = glmath.vec2, glmath.vec3, glmath.vec4
local mat3, mat4 = glmath.mat3, glmath.mat4
local abs, min, max = math.abs, math.min, math.max
local mix = glmath.mix
local pi, sin, cos, acos = math.pi, math.sin, math.cos, math.acos
local infinity = math.huge
local floatsz, ushortsz = gl.sizeof('float'), gl.sizeof('ushort')

-- Utilities that convert generic tables to glmath types:
local function tovec2(v) return vec2(v[1], v[2]) end
local function todir3(v) return vec3(v[1], v[2], 0.0) end -- 2D direction in homog. coords
local function topos3(v) return vec3(v[1], v[2], 1.0) end -- 2D position in homog. coords
local function tomat3(m) -- 2D transform in homog. coords
   return mat3(m[1][1], m[1][2], m[1][3],
               m[2][1], m[2][2], m[2][3],
                   0.0,     0.0,     1.0)
end

local vao1, vbo1, ebo1, vao2, vbo2, vao3, vbo3
local prog1, vsh1, fsh1, prog2, vsh2, fsh2, prog3, vsh3, fsh3
local loc1, loc2, loc3 = {}, {}, {} -- locations of uniform variables

-- Colors
local BLACK = vec4(0.0, 0.0, 0.0, 1.0)
local WHITE = vec4(1.0, 1.0, 1.0, 1.0)
local NOCOLOR = vec4(0.0, 0.0, 0.0, 0.0) -- transparent
local COLOR1 = vec4(0x58/255, 0x6e/255, 0x75/255, 1.0)
local COLOR2 = vec4(0x93/255, 0xa1/255, 0xa1/255, 1.0)
local COLORS = {
   vec4(0xb5/255.0, 0x89/255.0, 0x00/255.0, 1.0),
   vec4(0xcb/255.0, 0x4b/255.0, 0x16/255.0, 1.0),
   vec4(0xdc/255.0, 0x32/255.0, 0x2/255.0, 1.0),
   vec4(0xd3/255.0, 0x36/255.0, 0x82/255.0, 1.0),
   vec4(0x6c/255.0, 0x71/255.0, 0xc4/255.0, 1.0),
   vec4(0x26/255.0, 0x8b/255.0, 0xd2/255.0, 1.0),
   vec4(0x2a/255.0, 0xa1/255.0, 0x98/255.0, 1.0),
   vec4(0x85/255.0, 0x99/255.0, 0x00/255.0, 1.0),
}

-------------------------------------------------------------------------------
-- 0. Viewing
-------------------------------------------------------------------------------

local W, H -- current window dimensions
local view, projection = mat4(), mat4() -- current view and projection matrices

local function resize(w, h)
-- Call this at window resize.
   W, H = w, h
   gl.use_program(prog3)
   gl.uniform_matrix4f(loc3.projection, true, ortho(0, W, H, 0, 1, -1))
end

local function set_matrices(view_matrix, projection_matrix)
   view = view_matrix or view
   projection = projection_matrix or projection
   gl.use_program(prog1)
   gl.uniform_matrix4f(loc1.U_vp_matrix, true, projection*view)
   gl.use_program(prog2)
   gl.uniform_matrix4f(loc2.view, true, view)
   gl.uniform_matrix4f(loc2.projection, true, projection)
end

local function screen_to_world(x, y)
-- Converts the given cursor coordinates (x,y) back to world-space coordinates.
-- This should work only under the assumption that in the opposite direction (from
-- world-space to screen space) the perspective division was ininfluent, which is
-- true if ortographic projection is used.
--  
--   Screen-space         Clip-space       
--    (cursor)                yc          
--                             |             x = (xc+1)*W/2
--  (0,0)-------->x         __+1___          y = (1-yc)*H/2
--    |        |         -1|   |   |+1        
--    |        |        --------------> xc   xc = 2*x/W-1     
--    |________|           |___|___|         yc = 1-2*y/H   
--    |      (W,H)            -1                        
--    y                        |
   local pos = vec4(2*x/W-1, 1-2*y/H, 0, 1) -- clip-space coords
   pos = (projection*view)^-1 * pos         -- world-space coords
   return pos.x, pos.y
end

local function new_camera(eye)
-- A simple ortographic camera that always looks down the -z axis and is
-- initially oriented with the +x axis on its right and the +y axis up.
   local eye = eye or vec3(0,0,0)
   local up = vec3(0,1,0)
   local front = vec3(0,0,-1)
   local z_axis = vec3(0,0,1)
   local at = eye+front
   local scale = 1.0
   return setmetatable({}, {
   __index = {
      view = function(camera)
         return look_at(eye, at, up)
      end,
      projection = function(camera, left, right, bottom, top)
         return ortho(left*scale, right*scale, bottom*scale, top*scale, 0, -1, 1)
      end,
      set_pos = function(camera, v) pos = vec3(v) end,
      set_up = function(camera, v) up = vec3(v):normalize() end,
      move = function(camera, dir, speed, dt)
         local ds = speed*dt
         if     dir=='up'    then eye.y = eye.y - ds
         elseif dir=='down'  then eye.y = eye.y + ds
         elseif dir=='left'  then eye.x = eye.x - ds
         elseif dir=='right' then eye.x = eye.x + ds
         end
         at = eye+front
      end,
      zoom = function(camera, dir, speed, dt)
         local ds = speed*dt
         if     dir=='in'  then scale = max(scale-ds, 0)
         elseif dir=='out' then scale = scale+ds
         end
      end,
      rotate = function(camera, dir, ang_speed, dt)
         local angle
         if     dir=='ccw' then angle = ang_speed*dt
         elseif dir=='cw' then  angle = -ang_speed*dt
         end
         up = mat3(rotate(angle, z_axis))*up
      end,
   },
   })
end

local function toggle_fullscreen(window)
-- Returns a function that, each time it is called, toggles from
-- windowed mode to fullscreen mode or viceversa.
   local window = window
   local isfullscreen = false
   local x, y, w, h
   return function ()
      if not isfullscreen then
         x, y = glfw.get_window_pos(window)
         w, h = glfw.get_window_size(window)
         local monitor = glfw.get_primary_monitor()
         local vmode = glfw.get_video_mode(monitor)
         isfullscreen = true
         glfw.set_window_monitor(window, monitor, 0, 0, vmode.width, vmode.height)
      else
         isfullscreen = false
         glfw.set_window_monitor(window, nil, x, y, w, h)
      end
   end
end

-------------------------------------------------------------------------------
-- 1. Shapes renderer
-------------------------------------------------------------------------------
-- This is a port of Chipmunk's original debug draw demo implementation.

local vshader1 = [[
#version 330 core
layout(location = 0) in vec2 IN_pos;
layout(location = 1) in vec2 IN_uv;
layout(location = 2) in float IN_radius;
layout(location = 3) in vec4 IN_fill;
layout(location = 4) in vec4 IN_outline;
uniform mat4 U_vp_matrix;
out struct {
   vec2 uv;
   vec4 fill;
   vec4 outline;
} FRAG;
void main()
   {
   gl_Position = U_vp_matrix*vec4(IN_pos + IN_radius*IN_uv, 0, 1);
   FRAG.uv = IN_uv;
   FRAG.fill = IN_fill;
   FRAG.fill.rgb *= IN_fill.a;
   FRAG.outline = IN_outline;
   FRAG.outline.a *= IN_outline.a;
   }
]]

local fshader1 = [[
#version 330 core
in struct {
   vec2 uv;
   vec4 fill;
   vec4 outline;
} FRAG;
out vec4 OUT_color;
void main()
   {
   float len = length(FRAG.uv);
   float fw = length(fwidth(FRAG.uv));
   float mask = smoothstep(-1, fw - 1, -len);
   float outline = 1 - fw;
   float outline_mask = smoothstep(outline - fw, outline, len);
   vec4 color = FRAG.fill + (FRAG.outline - FRAG.fill*FRAG.outline.a)*outline_mask;
   OUT_color = color*mask;
   }
]]

local uniforms4 = { "U_vp_matrix" }

local point_line_scale = 1.0
local max_vertex = 64*1024
local max_index = 4*max_vertex

local function init_debug_draw()
   prog1, vsh1, fsh1 = gl.make_program_s({vertex=vshader1, fragment=fshader1})
   for _, name in ipairs(uniforms4) do loc1[name]= gl.get_uniform_location(prog1, name) end
   vao1 = gl.new_vertex_array()
   vbo1 = gl.new_buffer('array')
   local stride = 13*floatsz
   gl.buffer_data('array', max_vertex*stride, 'dynamic draw')
   gl.enable_vertex_attrib_array(0) -- pos
   gl.vertex_attrib_pointer(0, 2, 'float', false, stride, 0)
   gl.enable_vertex_attrib_array(1) -- uv
   gl.vertex_attrib_pointer(1, 2, 'float', false, stride, 2*floatsz)
   gl.enable_vertex_attrib_array(2) -- radius
   gl.vertex_attrib_pointer(2, 1, 'float', false, stride, 4*floatsz)
   gl.enable_vertex_attrib_array(3) -- fill color
   gl.vertex_attrib_pointer(3, 4, 'float', false, stride, 5*floatsz)
   gl.enable_vertex_attrib_array(4) -- outline color
   gl.vertex_attrib_pointer(4, 4, 'float', false, stride, 9*floatsz)
   ebo1 = gl.new_buffer('element array')
   gl.buffer_data('element array', max_index*ushortsz, 'dynamic draw')
   gl.unbind_buffer('array')
   gl.unbind_vertex_array()
end

local function color_for_shape(shape)
   if shape:get_sensor() then return WHITE end
   local body = shape:get_body()
   if body:is_sleeping() then return COLOR1 end
   local idle_time = body:get_idle_time()
   local sleep_time_threshold = shape:get_space():get_sleep_time_threshold()
   if idle_time > sleep_time_threshold then return COLOR2 end
   local val = shape:get_hashid()
   -- scramble the bits up using Robert Jenkins' 32 bit integer hash function
   val = ((val+0x7ed55d16) + (val<<12))
   val = ((val~0xc761c23c) ~ ((val&0xffffffff)>>19))
   val = ((val+0x165667b1) + (val<<5))
   val = ((val+0xd3a2646c) ~ (val<<9))
   val = ((val+0xfd7046c5) + (val<<3))
   val = ((val~0xb55a4f09) ~ ((val&0xffffffff)>>16))
   local index = (val & 0x7) + 1
   return COLORS[index]
end

local function renderer(space)
   local space = space
   local vertexsz = 13*floatsz

   local vdata, idata, vcount, icount
   local function begin()
      vdata, idata, vcount, icount = {}, {}, 0, 0 
   end

   local function push_vertices(vertices, indices, nv, ni)
   -- vertices = table containing nv vertices, where
   --            vertex = {pos, tc, radius, fill_color, outline_color}
   --                       2   2     1        4           4          = 13 floats
   -- indices = flat table containing ni indices, 0-based and relative to vertices
   --           (i.e., 0 corresponds to the first vertex in vertices)
      table.insert(vdata, vertices)
      for _, i in ipairs(indices) do table.insert(idata, vcount+i) end -- offset by vcount
      vcount, icount = vcount+nv, icount+ni
   end

   local function done()
      if vcount==0 or icount==0 then return end
      local vdata = gl.packf(vdata)
      local idata = gl.packus(idata)
      assert(#vdata == vertexsz*vcount and #idata == ushortsz*icount 
            and vcount <= max_vertex and icount <= max_index)
      gl.enable('blend')
      gl.blend_func('one', 'one minus src alpha')
      gl.use_program(prog1)
      gl.bind_vertex_array(vao1)
      gl.bind_buffer('array', vbo1)
      gl.buffer_sub_data('array', 0, vdata)
      gl.bind_buffer('element array', ebo1)
      gl.buffer_sub_data('element array', 0, idata)
      gl.draw_elements('triangles', icount, 'ushort', 0)
   end

   -- Note: these functions do not assume that vectors and colors are given
   -- as glmath types (they just expect them to be table arrays of numbers).

   local fat_segment_indices = {0, 1, 2, 1, 2, 3, 2, 3, 4, 3, 4, 5, 4, 5, 6, 5, 6, 7}

   local function draw_fat_segment(a, b, radius, outline_color, fill_color)
      local a, b = tovec2(a), tovec2(b)
      local t = (b - a):normalize()
      local r = radius + point_line_scale
      local vertices = {
          a, -t.x+t.y, -t.x-t.y, r, fill_color, outline_color,
          a, -t.x-t.y,  t.x-t.y, r, fill_color, outline_color,
          a,      t.y, -t.x    , r, fill_color, outline_color,
          a,     -t.y,  t.x    , r, fill_color, outline_color,
          b,      t.y, -t.x    , r, fill_color, outline_color,
          b,     -t.y,  t.x    , r, fill_color, outline_color,
          b,  t.x+t.y, -t.x+t.y, r, fill_color, outline_color,
          b,  t.x-t.y,  t.x+t.y, r, fill_color, outline_color,
      }
      push_vertices(vertices, fat_segment_indices, 8, 18)
   end

   local function draw_segment(a, b, color)
      draw_fat_segment(a, b, 0.0, color, color)
   end

   local circle_indices = {0, 1, 2, 0, 2, 3}

   local function draw_circle(pos, angle, radius, outline_color, fill_color)
      local pos = tovec2(pos)
      local r = radius + point_line_scale
      local vertices = {
         pos, -1, -1, r, fill_color, outline_color,
         pos, -1,  1, r, fill_color, outline_color,
         pos,  1,  1, r, fill_color, outline_color,
         pos,  1, -1, r, fill_color, outline_color,
      }
      push_vertices(vertices, circle_indices, 4, 6)
      local dir = cp.vforangle(angle)
      draw_segment(pos, pos+0.75*radius*tovec2(dir), outline_color)
   end

   local function draw_polygon(verts, radius, outline_color, fill_color)
      local count = #verts
      for i, v in ipairs(verts) do verts[i] = tovec2(v) end
      local indices = {}
      -- Polygon fill triangles (count-2 triangles).
      for i = 0, count-3 do
         table.insert(indices, {0, 4*(i+1), 4*(i+2) })
      end
      -- Polygon outline triangles (4*count triangles).
      for i=0, count-1 do
         local i0 = 4*i
         local i1 = 4*((i+1)%count)
         table.insert(indices, { i0  , i0+1, i0+2,
                                 i0  , i0+2, i0+3,
                                 i0  , i0+3, i1  ,
                                 i0+3, i1  , i1+1, })
      end
      local inset = -max(0, 2*point_line_scale - radius)
      local outset = radius + point_line_scale
      local r = outset - inset
      local vertices = {}
      for i=0, count-1 do
         local v0 = verts[i+1]
         local v_prev = verts[(i+(count-1))%count+1]
         local v_next = verts[(i+(count+1))%count+1]
         local n1 = (v0 - v_prev):normalize()
         local n2 = (v_next - v0):normalize()
         n1 = vec2(n1.y, -n1.x) -- rperp
         n2 = vec2(n2.y, -n2.x)
         local of = (n1+n2)/(n1*n2+1.0)
         local v = v0 + inset*of
         table.insert(vertices, {
            v,  0.0,  0.0, 0.0, fill_color, outline_color,
            v, n1.x, n1.y,   r, fill_color, outline_color,
            v, of.x, of.y,   r, fill_color, outline_color,
            v, n2.x, n2.y,   r, fill_color, outline_color})
      end
      push_vertices(vertices, gl.flatten_table(indices), 4*count, 3*(5*count-2))
   end

   local dot_indices = {0, 1, 2, 0, 2, 3}

   local function draw_dot(size, pos, color)
      local pos = tovec2(pos)
      local r = size*.5*point_line_scale
      local vertices = {
         pos, -1.0,-1.0, r, color, color,
         pos, -1.0, 1.0, r, color, color,
         pos,  1.0, 1.0, r, color, color,
         pos,  1.0,-1.0, r, color, color,
      }
      push_vertices(vertices, dot_indices, 4, 6)
   end

   local function draw_box(bb, color)
      local l, r, b, t = table.unpack(bb)
      draw_polygon({{r, b}, {r, t}, {l, t}, {l, b}}, 0, color, NOCOLOR)
   end

   space:set_debug_draw_options(
      draw_circle,
      draw_segment,
      draw_fat_segment,
      draw_polygon,
      draw_dot,
      color_for_shape,
      cp.debugdrawflags('shapes', 'constraints', 'points'),
      {0xee/255.0, 0xe8/255.0, 0xd5/255.0, 1.0}, -- outline color
      {0.0, 0.75, 0.0, 1.0},                     -- constraint color
      {1.0, 0.0, 0.0, 1.0})                      -- collision point color

   return setmetatable({}, {
   __index = {
      begin = function(renderer) begin() end,
      push = function(renderer, ...) push_vertices(...) end,
      draw_fat_segment = function(renderer, ...) draw_fat_segment(...) end,
      draw_segment = function(renderer, ...) draw_segment(...) end,
      draw_circle = function(renderer, ...) draw_circle(...) end,
      draw_polygon = function(renderer, ...) draw_polygon(...) end,
      draw_dot = function(renderer, ...) draw_dot(...) end,
      draw_box = function(renderer, ...) draw_box(...) end,
      done = function(renderer) done() end,
      },
   })
end

-------------------------------------------------------------------------------
-- 2. Sprites renderer
-------------------------------------------------------------------------------
-- Based on Joey De Vries' tutorials at learnopengl.com:
-- https://learnopengl.com/#!In-Practice/2D-Game/Rendering-Sprites 

local vshader2 = [[
#version 330 core
layout (location = 0) in vec4 vertex; // <vec2 position, vec2 texcoords>
out vec2 texcoords;
uniform mat4 model;
uniform mat4 projection;
uniform mat4 view;
uniform vec4 portion;
void main() {
   texcoords = portion.xy + vertex.zw*(portion.zw - portion.xy);
   gl_Position = projection*view*model*vec4(vertex.xy, 0.0, 1.0);
}
]]
local fshader2 = [[
#version 330 core
in vec2 texcoords;
out vec4 outcolor;
uniform sampler2D image;
uniform vec4 color;
void main() {
   outcolor = color * texture(image, texcoords);
}
]]

local uniforms2 = { "model", "view", "projection", "color", "portion" }

local function init_sprites()
   prog2, vsh2, fsh2 = gl.make_program_s({vertex=vshader2, fragment=fshader2})
   for _, name in ipairs(uniforms2) do loc2[name]=gl.get_uniform_location(prog2, name) end
   -- Initialize and configure the quad's buffer and vertex attributes
   vao2 = gl.new_vertex_array()
   vbo2 = gl.new_buffer('array')
   local vertices = gl.pack('float', {
   -- Position    TexCoord
      -.5,  .5,   0.0, 1.0,   -- A     A---B
      -.5, -.5,   0.0, 0.0,   -- C     | ./|___ x
       .5,  .5,   1.0, 1.0,   -- B     |/| |
      -.5, -.5,   0.0, 0.0,   -- C     C---D
       .5, -.5,   1.0, 0.0,   -- D       |
       .5,  .5,   1.0, 1.0,   -- B       V y
   })
   gl.buffer_data('array', vertices, 'static draw')
   gl.enable_vertex_attrib_array(0)
   gl.vertex_attrib_pointer(0, 4, 'float', false, 4*floatsz, 0)
   gl.unbind_buffer('array')
   gl.unbind_vertex_array()
end

local PORTION = vec4(0.0, 0.0, 1.0, 1.0)

local function new_sprite(filename, channels, wrap_s, wrap_t, min_filter, mag_filter)
-- Creates a sprite loading the texture data from filename.
-- channels = 'rgba' | 'rgb'
   assert(mi, "this functionality requires MoonImage")
   mi.flip_vertically_on_load(true)
   local data, w, h = mi.load(filename, channels)
   local sprite = {}
   local texid = gl.new_texture('2d')
   gl.texture_image('2d', 0, channels or 'rgb', channels or 'rgb', 'ubyte', data, w, h)
   gl.texture_parameter('2d', 'wrap s', wrap_s or 'repeat')
   gl.texture_parameter('2d', 'wrap t', wrap_t or 'repeat')
   gl.texture_parameter('2d', 'min filter', min_filter or 'linear')
   gl.texture_parameter('2d', 'mag filter', mag_filter or 'linear')
   gl.unbind_texture('2d')

   return setmetatable({}, {
   __index = {
      draw = function(sprite, pos, size, rot, color, portion)
         -- pos:     where to draw the center of the quad (vec2)
         -- size:    optional scaling factors in the x and y directions (vec2)
         -- rot:     optional angle of ccw rotation around the quad center (radians)
         -- color:   optional color to apply to the sprite (vec4)
         -- portion: optional description of the texture portion (vec4)
         -- Pass portion=vec4(u1,v1,u2,v2) to draw only the portion of the texture
         -- delimited by P1=(u1,v1) and P2=(u2,v2),
         --   y
         --   ^                               (0,1)---------(1,1)
         --   |    A___B    ^                   |             |
         --   |    | ./|    |                   |    .---P2   |
         --   |    |/__|   / rotation           |    |   |<---|-- portion
         --   |    C   D  /                     |   P1---'    |
         --   |       ---'                    (0,0----------(1,0)
         -- (0,0)---------------->x
         --   
         local color = color or WHITE
         local portion = portion or PORTION
         gl.use_program(prog2)
         local model = translate(pos[1], pos[2], 0)
         if rot then model = model*rotate(rot, 0, 0, 1) end
         if size then model = model*scale(size[1], size[2], 1) end
         gl.uniform_matrix4f(loc2.model, true, model)
         gl.uniformf(loc2.color, color)
         gl.uniformf(loc2.portion, portion)
         -- Render textured quad
         gl.enable('blend')
         gl.blend_func('src alpha', 'one minus src alpha')
         gl.active_texture(0)
         gl.bind_texture('2d', texid)
         gl.bind_vertex_array(vao2)
         gl.draw_arrays('triangles', 0, 6)
         gl.unbind_vertex_array()
      end,

      texid = function(sprite) return texid end,

      delete = function(sprite)
         if not texid then return end
         gl.delete_texture(texid)
         texid = nil
      end,
      },
   __gc = function(sprite) sprite:delete() end,
   })
end

-------------------------------------------------------------------------------
-- 3. Fonts (text renderer)
-------------------------------------------------------------------------------
-- Based on Joey De Vries' tutorials at learnopengl.com:
-- https://learnopengl.com/#!In-Practice/Text-Rendering

local loaded_fonts = {} -- keeps track of all the loaded fonts

local vshader3 = [[
#version 330 core
layout (location = 0) in vec4 Vertex; // <vec2 pos, vec2 tex>
out vec2 texcoords;
uniform mat4 projection;
void main() {
   gl_Position = projection * vec4(Vertex.xy, 0.0, 1.0);
   texcoords = Vertex.zw;
}
]]
local fshader3 = [[
#version 330 core
in vec2 texcoords;
out vec4 outcolor;
uniform sampler2D text;
uniform vec4 color;
void main() {    
   outcolor = color * vec4(1.0, 1.0, 1.0, texture(text, texcoords).r);
}
]]

local uniforms3 = { "projection", "color", "text" }

local function init_fonts()
   prog3, vsh3, fsh3 = gl.make_program_s({vertex=vshader3, fragment=fshader3})
   gl.use_program(prog3)
   for _, name in ipairs(uniforms3) do loc3[name]=gl.get_uniform_location(prog3, name) end
   gl.uniformi(loc3.text, 0)

   vao3 = gl.new_vertex_array()
   vbo3 = gl.new_buffer('array')
   gl.buffer_data('array', floatsz*6*4, 'dynamic draw')
   gl.enable_vertex_attrib_array(0)
   gl.vertex_attrib_pointer(0, 4, 'float', false, 4*floatsz, 0)
   gl.unbind_buffer('array')
   gl.unbind_vertex_array()
   gl.pixel_store('unpack alignment', 1) -- disable OpenGL byte-alignment restriction
end

local function new_font(fontpathname, font_size)
-- Loads the givent font and pre-compiles a list of characters
-- font_size = 0..1, normalized size relative to the window height H
   assert(ft, "this functionality requires MoonFreeType")
   assert(font_size > 0 and font_size <= 1, "invalid font size")
   -- Initialize and load the FreeType library
   local ftlib = ft.init_freetype()
   -- load the font face and set the desired glyph size
   local face = ft.new_face(ftlib, fontpathname)
   face:set_pixel_sizes(0, math.floor(font_size*H+.5))

   local font = {}
   -- Pre-load the first 128 ASCII characters
   font.char = {}
   for c = 0, 127 do 
      -- Load glyph
      face:load_char(c, ft.LOAD_RENDER)
      local glyph = face:glyph()
      local bitmap = glyph.bitmap
      -- Generate texture and set texture options
      local texid = gl.new_texture('2d')
      gl.texture_image('2d', 0, 'red', 'red', 'ubyte', bitmap.buffer, bitmap.width, bitmap.rows)
      gl.texture_parameter('2d', 'wrap s', 'clamp to edge')
      gl.texture_parameter('2d', 'wrap t', 'clamp to edge')
      gl.texture_parameter('2d', 'min filter', 'linear')
      gl.texture_parameter('2d', 'mag filter', 'linear')
      -- Store character info for later use
      font.char[c] = {
         texid = texid,
         size = vec2(bitmap.width, bitmap.rows), -- glyph size
         bearing = vec2(bitmap.left, bitmap.top), -- offset from baseline to left/top of glyph
         advance = glyph.advance.x -- horizontal offset to advance to next glyph
      }
      -- print("Added "..string.char(c) .. " ("..c..")")
   end
   gl.unbind_texture('2d')
   face:done()
   ftlib:done()
   font.hby = font.char[string.byte('H')].bearing.y
   font.size = font_size
   loaded_fonts[font] = font

   return setmetatable(font, {
   __index = {
      text_width = function(font, text, size)
         -- Computes the width of the given text, relative to the window width (1=W).
         -- text: the string of text.
         -- size: font size relative to the window height (1=H).
         local scale = size*H/font.hby
         local x = 0
         for i = 1, #text do
            local ch = font.char[text:byte(i)]
            x = x + (ch.advance >> 6)*scale
         end
         return x/W
      end,

      delete = function(font) 
         if not loaded_fonts[font] then return nil end
         assert(loaded_fonts[font] == font)
         for _, c in pairs(font.char) do gl.delete_textures(c.texid) end
         loaded_fonts[font] = nil
      end,

      draw = function(font, text, x, y, size, color)
         -- Renders a string of text using this font.
         -- text: the string of text.
         -- x, y: normalized position (1,1=W,H) of the text's top left corner
         -- size: size, relative to the window height (1=H).
         -- color: vec4
         local x, y = x*W, y*H
         local hby = font.hby
         local scale = size*H/hby
         gl.use_program(prog3)
         gl.enable('blend')
         gl.blend_func('src alpha', 'one minus src alpha')
         gl.uniformf(loc3.color, color or BLACK)
         gl.active_texture(0)
         gl.bind_vertex_array(vao3)

         for i = 1, #text do
            local c = text:byte(i)  -- numeric code for the i-th character
            local ch = font.char[c] -- info for the character
            local xpos = x + ch.bearing.x*scale
            local ypos = y + (hby - ch.bearing.y)*scale
            local w = ch.size.x * scale
            local h = ch.size.y * scale
            -- Update the contents of vbo, and render the quad
            -- texturing it with this character's texture.
            gl.bind_buffer('array', vbo3)
            gl.buffer_sub_data('array', 0, gl.packf({
               { xpos,     ypos + h,   0.0, 1.0 },
               { xpos + w, ypos,       1.0, 0.0 },
               { xpos,     ypos,       0.0, 0.0 },
               { xpos,     ypos + h,   0.0, 1.0 },
               { xpos + w, ypos + h,   1.0, 1.0 },
               { xpos + w, ypos,       1.0, 0.0 }
            }))
            gl.unbind_buffer('array')
            gl.bind_texture('2d', ch.texid)
            gl.draw_arrays('triangles', 0, 6)
            -- Advance x position for the next glyph, if any
            x = x + (ch.advance >> 6) * scale -- = x + ch.advance/64 *scale
         end
         gl.unbind_vertex_array()
         gl.unbind_texture('2d')
      end,
   },
   __gc = function(font) font:delete() end,
   })
end

-------------------------------------------------------------------------------
-- 4. Sounds
-------------------------------------------------------------------------------

local sound_device, sound_context

local function init_sounds()
   assert(al, "this functionality requires MoonAL")
   assert(sf, "this functionality requires MoonSndFile")
   sound_device = al.open_device()
   sound_context = al.create_context(sound_device)
end

local function loadsoundfile(filename)
-- Load sound data and metadata from the given sound file.
   local sndfile, info = sf.open(filename, "r")
   local data = sndfile:read('float', info.frames)
   local format
   if info.channels == 1 then format = 'mono float32'
   elseif info.channels == 2 then format = 'stereo float32'
   else error("unexpected number of channels in sound file")
   end
   sf.close(sndfile) -- we don't need it any more
   return data, format, info.samplerate
end

local function new_sound_sample(filename)
-- Create a new sound sample from the given sound file.
-- A 'sound sample' here is an object holding a dedicated OpenAL source,
-- whose buffer is set with the data from the given file.
-- The sample object has methods to play/pause/stop/rewind it.
   assert(sound_context, "sounds functionality is not initialized")
   local data, format, srate = loadsoundfile(filename)
   local buffer = al.create_buffer(sound_context)
   al.buffer_data(buffer, format, data, srate)
   data = nil; collectgarbage()
   local source = al.create_source(sound_context)
   source:set('buffer', buffer)
   buffer = buffer
   return setmetatable({}, {
   __index = {
      play = function(sample, loop)
         -- Play the sound sample, optionally looping it (if loop=true).
         source:set('looping', loop and true or false)
         source:play()
      end,

      stop = function(sample) source:stop() end,
      pause = function (sample) source:pause() end,
      rewind = function (sample) source:rewind() end,

      delete = function(sample)
         if not sample then return end
         al.delete_source(source)
         al.delete_buffer(buffer)
         source, buffer = nil
      end,
   },

   __gc = function(sample) sample:delete() end,
   })
end


-------------------------------------------------------------------------------
-- 5. Frame timer
-------------------------------------------------------------------------------
-- Derived from Cyclone-Physics engine, by Ian Millington
-- (https://github.com/idmillington/cyclone-physics )
-- All timestamps and time intervals are in seconds.

local function new_frame_timer()
   local now = glfw.now
   local start_time = now() -- reset_time, relative to now()'s time zero
   local fn = 0 -- current frame number
   local ft = 0.0 -- current frame time, relative to start_time
   local dt = 0.0 -- current frame duration
   local spf = 0.0 -- 1/fps, seconds per frame (recency weighted average of frame duration)
   local paused = false -- true if the timer is paused, false otherwise
   local mt = {
      __index = {
         reset = function(timer)
            start_time = now()
            dt, ft, fn, spf, paused = 0.0, 0.0, 0, 0.0, false
         end,
         update = function(timer)
            -- Update the timing system. Call this once per frame.
            if not paused then fn = fn + 1 end
            local tmp = now() - start_time
            dt, ft = tmp - ft, tmp
            if fn > 1 then
               spf = spf <= 0 and dt or .99*spf + .01*dt -- RWA over 100 frames
            end
            return dt -- , ft, fn, 1/spf, paused 
         end,

         info = function(timer) return dt, ft, fn, 1/spf, paused end,
         fn = function(timer) return fn end,
         ft = function(timer) return ft end,
         dt = function(timer) return dt end,
         fps = function(timer) return 1/spf end,
         pause = function(timer) paused = true end,
         resume = function(timer) paused = false end,
         ispaused = function(timer) return paused end,
         start_time = function(timer) return start_time end,
      },
      __tostring = function(timer)
            return string.format("dt=%.3f ft=%.3f fn=%d, fps=%.1f paused=%s",
                     dt, ft, fn, 1/spf, tostring(paused))
      end,
      __concat = function(a, b) return tostring(a) .. tostring(b) end,
      }
   return setmetatable({}, mt)
end

local function new_fixed_dt_counter(fdt)
-- Returns a function that counts the number of fixed time intervals fdt
-- elapsed in a (possibly variable) time interval dt, and keeps track of
-- the remainder to account for it the next time it is called.
   local fdt = fdt
   local n, tot_dt, remainder = 0, 0, 0
   return function(dt)
      tot_dt = dt + remainder
      n, remainder = tot_dt//fdt, tot_dt%fdt
      return n
   end
end

-------------------------------------------------------------------------------
-- 6. Mouse grabbing system
-------------------------------------------------------------------------------


local function new_grabber(window, space)
   local space, window = space, window
   local mouse_body = cp.body_new_kinematic()
   local mouse_pos = vec2(screen_to_world(glfw.get_cursor_pos(window)))
   local mouse_joint = false
   local mask = (1<<31) -- grabbable bitmask
   local grab_filter = { group=0, categories=mask, mask=mask }

   return setmetatable({},{
   __index = {
      get_pos = function(grabber)
         local x, y = glfw.get_cursor_pos(window)
         mouse_pos = vec2(screen_to_world(x, y))
         return vec2(mouse_pos)
      end,

      filters = function(grabber)
         -- shape filters (to make shapes grabbable/non-grabbable in queries):
         return   { group=0, categories=mask, mask=mask },  -- grab filter
                  { group=0, categories=~mask, mask=~mask } -- non-grabbable filter
      end,

      cursor_pos_callback = function(grabber, x, y)
         -- to be called in the glfw cursor_pos_callback
         mouse_pos = vec2(screen_to_world(x, y))
      end,

      mouse_button_callback = function(grabber, button, action, shift, control, alt, super)
         -- to be called in the glfw mouse_button_callback
         if button == 'left' then
            if action == 'press' then
               -- left button click: check if there is a grabbable shape near the cursor,
               -- and if there is one, create a joint between its body and the mouse's
               -- kinematic body, so that moving the mouse while keeping the button pressed
               -- will have the effect to drag the shape around.
               -- Give the mouse click a little radius to make it easier to click small shapes.
               local info = space:point_query_nearest(mouse_pos, 5.0, grab_filter)
               if info then
                  local body = info.shape:get_body()
                  if body:get_mass() < infinity then
                     -- if the click is outside the shape, use the closest point on the shape
                     -- as second anchor, otherwise use the click position (the first ancor
                     -- is the center of the mouse_body, i.e. {0,0} in local coordinates).
                     local nearest = info.distance > 0 and info.point or mouse_pos
                     local anchor = body:world_to_local(nearest)
                     mouse_joint = cp.pivot_joint_new(mouse_body, body, {0,0}, anchor)
                     mouse_joint:set_max_force(50000.0)
                     mouse_joint:set_error_bias((1.0 - 0.15)^60.0)
                     space:add_constraint(mouse_joint)
                  end
               end
            else
               -- left button released: delete the joint (if any)
               if mouse_joint then
                  space:remove_constraint(mouse_joint)
                  mouse_joint:free()
                  mouse_joint = false
               end
            end
         end
      end,
      step = function(grabber, fdt, n)
         -- Updates the kinematic body associated with the mouse.
         -- To be called whenever space:step() is called, with the same args.
         local n = n or 1
         local p, newp
         for i = 1, n do
            p = tovec2(mouse_body:get_position())
            newp = mix(p, mouse_pos, 0.25)
            mouse_body:set_position(newp)
            mouse_body:set_velocity((newp-p)*60)
         end
      end,
      },
   })
end


-------------------------------------------------------------------------------
-- Initialization and cleanup
-------------------------------------------------------------------------------

local function init(w, h, sounds)
   assert(not prog2, "double initialization")
   init_debug_draw()
   init_sprites()
   init_fonts()
   if sounds then init_sounds() end
   resize(w, h)
   set_matrices(mat4(), mat4())
end

local function cleanup()
   gl.delete_buffers(vbo1, ebo1, vbo2, vbo3)
   vbo1, ebo1, vbo2, vbo3 = nil
   gl.delete_vertex_arrays(vao1, vao2, vao3)
   vao1, vao2, vao3 = nil
   gl.delete_shaders(vsh1, fsh1, vsh2, fsh2, vsh3, fsh3)
   vsh1, fsh1, vsh2, fsh2, vsh3, fsh3 = nil
   gl.delete_programs(prog1, prog2, prog3)
   prog1, prog2, prog3 = nil
   for _, font in pairs(loaded_fonts) do font:delete() end
   loaded_fonts = {}
   if sound_context then al.delete_context(sound_context) end
   if sound_device then al.close_device(sound_device) end
   sound_device, sound_context = nil
end

return {
   init = init,
   cleanup = cleanup,
   resize = resize,
   set_matrices = set_matrices,
   screen_to_world = screen_to_world,
   camera = new_camera,
   toggle_fullscreen = toggle_fullscreen,
   renderer = renderer,
   sprite = new_sprite,
   font = new_font,
   frame_timer = new_frame_timer,
   fixed_dt_counter = new_fixed_dt_counter,
   sound_sample = new_sound_sample,
   grabber = new_grabber,
   tovec2 = tovec2,
   topos3 = topos3,
   todir3 = todir3,
   tomat3 = tomat3,
}

