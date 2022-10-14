cmake_minimum_required(VERSION 3.17)

project(moonchipmunk)

find_package(Lua REQUIRED)

#needs to be manually created until chipmunk provides a chipmunkConfig.cmake
find_package(chipmunk REQUIRED)

add_library(moonchipmunk SHARED
	src/compat-5.3.h
	src/constraint.h
	src/enums.h
	src/internal.h
	src/moonchipmunk.h
	src/objects.h
	src/tree.h
	src/udata.h
	src/arbiter.c
	src/body.c
	src/circle.c
	src/collision_handler.c
	src/compat-5.3.c
	src/constraint.c
	src/damped_rotary_spring.c
	src/damped_spring.c
	src/datastructs.c
	src/enums.c
	src/flags.c
	src/gear_joint.c
	src/groove_joint.c
	src/main.c
	src/misc.c
	src/objects.c
	src/pin_joint.c
	src/pivot_joint.c
	src/poly.c
	src/ratchet_joint.c
	src/rotary_limit_joint.c
	src/segment.c
	src/shape.c
	src/simple_motor.c
	src/slide_joint.c
	src/space.c
	src/tracing.c
	src/udata.c
	src/utils.c
)

target_include_directories(moonchipmunk PUBLIC
	${LUA_INCLUDE_DIR}
	${chipmunk_INCLUDE_DIR}
)

target_link_libraries(moonchipmunk
	${LUA_LIBRARIES}
	${chipmunk_LIBS}
)

install(TARGETS moonchipmunk LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(TARGETS moonchipmunk RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
