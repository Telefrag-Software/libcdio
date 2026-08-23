cmake_minimum_required(VERSION 3.5...4.2.1 FATAL_ERROR)

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

option(LIBCDIO_BUILD_CXX_WRAPPER "Build C++ wrapper library." ON)
option(LIBCDIO_ENABLE_JOLIET "Enable ISO-9660 Joliet support." ON)
option(LIBCDIO_ENABLE_ROCK "Enable ISO-9660 Rock Ridge support." ON)

file(READ "${CMAKE_CURRENT_SOURCE_DIR}/configure.ac" AUTOMAKE_CONTENTS)

string(REGEX MATCH
	"define\\([ \t]*RELEASE_NUM[ \t]*,[ \t]*([0-9]+\\.[0-9]+\\.[0-9]+)[ \t]*\\)"
	_RELEASE_NUM_MATCH
	"${AUTOMAKE_CONTENTS}"
)

if(NOT _RELEASE_NUM_MATCH)
	message(FATAL_ERROR "Failed to parse 'RELEASE_NUM' value from 'configure.ac' file.")
endif()

set(VERSION "${CMAKE_MATCH_1}")

string(REPLACE "." ";" _CDIO_VERSION_PARTS "${VERSION}")
list(GET _CDIO_VERSION_PARTS 0 _CDIO_VERSION_MAJOR)
list(GET _CDIO_VERSION_PARTS 1 _CDIO_VERSION_MINOR)
list(GET _CDIO_VERSION_PARTS 2 _CDIO_VERSION_PATCH)

math(EXPR LIBCDIO_VERSION_NUM "${_CDIO_VERSION_MAJOR} * 10000 + ${_CDIO_VERSION_MINOR} * 100 + ${_CDIO_VERSION_PATCH}")

find_package(Git QUIET)

if(GIT_FOUND AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
	execute_process(
		COMMAND git log -1 --format=%h
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		OUTPUT_VARIABLE GIT_COMMIT_HASH
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
endif()

if(NOT GIT_COMMIT_HASH)
	message(WARNING "Failed to determine Git commit hash.")
endif()

set(build "${GIT_COMMIT_HASH}")

set(_CDIO_VERSION_HEADER_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/include/cdio/version.h")

configure_file("${_CDIO_VERSION_HEADER_FILE_PATH}.in" "${_CDIO_VERSION_HEADER_FILE_PATH}" @ONLY)

project(libcdio VERSION ${VERSION} LANGUAGES C CXX)

include(Platform)

if(WIN32)
	set(_CDIO_CONFIGURATION_HEADER_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/.vs/config.h")
else()
	include(CheckDependencies)

	set(_CDIO_CONFIGURATION_HEADER_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src/config.h")

	configure_file("${_CDIO_CONFIGURATION_HEADER_FILE_PATH}.in" "${_CDIO_CONFIGURATION_HEADER_FILE_PATH}" @ONLY)
endif()

set(LIBRARY_NAME cdio)
set(WRAPPER_NAME cdio++)

set(LIBRARY_HEADER_FILES
	include/cdio/audio.h
	include/cdio/bytesex.h
	include/cdio/bytesex_asm.h
	include/cdio/cd_types.h
	include/cdio/cdio.h
	include/cdio/cdtext.h
	include/cdio/device.h
	include/cdio/disc.h
	include/cdio/ds.h
	include/cdio/dvd.h
	include/cdio/ecma_167.h
	include/cdio/iso9660.h
	include/cdio/logging.h
	include/cdio/memory.h
	include/cdio/mmc.h
	include/cdio/mmc_cmds.h
	include/cdio/mmc_hl_cmds.h
	include/cdio/mmc_ll_cmds.h
	include/cdio/mmc_util.h
	include/cdio/posix.h
	include/cdio/read.h
	include/cdio/rock.h
	include/cdio/scsi_mmc.h
	include/cdio/sector.h
	include/cdio/track.h
	include/cdio/types.h
	include/cdio/udf.h
	include/cdio/udf_file.h
	include/cdio/udf_time.h
	include/cdio/utf8.h
	include/cdio/util.h
	${_CDIO_VERSION_HEADER_FILE_PATH}
	include/cdio/xa.h
)

set(LIBRARY_SOURCE_FILES
	lib/driver/_cdio_generic.c
	lib/driver/_cdio_stdio.c
	lib/driver/_cdio_stdio.h
	lib/driver/_cdio_stream.c
	lib/driver/_cdio_stream.h
	lib/driver/abs_path.c
	lib/driver/aix.c
	lib/driver/audio.c
	lib/driver/cd_types.c
	lib/driver/cdio.c
	lib/driver/cdio_assert.h
	lib/driver/cdio_private.h
	lib/driver/cdtext.c
	lib/driver/cdtext_private.h
	lib/driver/device.c
	lib/driver/disc.c
	lib/driver/ds.c
	lib/driver/filemode.h
	lib/driver/generic.h
	lib/driver/gnu_linux.c
	lib/driver/image.h
	lib/driver/image_common.c
	lib/driver/image_common.h
	lib/driver/logging.c
	lib/driver/memory.c
	lib/driver/netbsd.c
	lib/driver/osx.c
	lib/driver/portable.h
	lib/driver/read.c
	lib/driver/realpath.c
	lib/driver/sector.c
	lib/driver/solaris.c
	lib/driver/track.c
	lib/driver/utf8.c
	lib/driver/util.c
	lib/driver/FreeBSD/freebsd.c
	lib/driver/FreeBSD/freebsd.h
	lib/driver/FreeBSD/freebsd_cam.c
	lib/driver/FreeBSD/freebsd_ioctl.c
	lib/driver/image/bincue.c
	lib/driver/image/cdrdao.c
	lib/driver/image/nrg.c
	lib/driver/image/nrg.h
	lib/driver/mmc/mmc.c
	lib/driver/mmc/mmc_cmd_helper.h
	lib/driver/mmc/mmc_hl_cmds.c
	lib/driver/mmc/mmc_ll_cmds.c
	lib/driver/mmc/mmc_private.h
	lib/driver/mmc/mmc_util.c
	lib/driver/MSWindows/aspi32.c
	lib/driver/MSWindows/aspi32.h
	lib/driver/MSWindows/win32.c
	lib/driver/MSWindows/win32.h
	lib/driver/MSWindows/win32_ioctl.c
	lib/iso9660/iso9660.c
	lib/iso9660/iso9660_fs.c
	lib/iso9660/iso9660_private.h
	lib/iso9660/rock.c
	lib/iso9660/xa.c
	lib/udf/filemode.c
	lib/udf/udf.c
	lib/udf/udf_file.c
	lib/udf/udf_fs.c
	lib/udf/udf_fs.h
	lib/udf/udf_private.h
	lib/udf/udf_time.c
)

if(WIN32)
	list(APPEND SPECIAL_LIBRARY_HEADER_FILES
		.vs/unistd.h
	)

	list(APPEND LIBRARY_SOURCE_FILES
		.vs/config.h
	)
else()
	list(APPEND LIBRARY_SOURCE_FILES
		${_CDIO_CONFIGURATION_HEADER_FILE_PATH}
	)
endif()

add_library(${LIBRARY_NAME} ${LIBRARY_HEADER_FILES} ${SPECIAL_LIBRARY_HEADER_FILES} ${LIBRARY_SOURCE_FILES})

add_library(${PROJECT_NAME}::${LIBRARY_NAME} ALIAS ${LIBRARY_NAME})

target_include_directories(${LIBRARY_NAME}
	PUBLIC
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
	PRIVATE
		${CMAKE_CURRENT_SOURCE_DIR}/include/cdio
		${CMAKE_CURRENT_SOURCE_DIR}/src
		${CMAKE_CURRENT_SOURCE_DIR}/lib
		${CMAKE_CURRENT_SOURCE_DIR}/lib/udf
		${CMAKE_CURRENT_SOURCE_DIR}/lib/iso9660
		${CMAKE_CURRENT_SOURCE_DIR}/lib/driver
		${CMAKE_CURRENT_SOURCE_DIR}/lib/driver/mmc
		${CMAKE_CURRENT_SOURCE_DIR}/lib/driver/image
		${CMAKE_CURRENT_SOURCE_DIR}/lib/driver/MSWindows
)

if(WIN32)
	target_include_directories(${LIBRARY_NAME}
		PRIVATE
			${CMAKE_CURRENT_SOURCE_DIR}/.vs
	)
endif()

if(NOT BUILD_SHARED_LIBS)
	target_compile_definitions(${LIBRARY_NAME}
		PUBLIC
			CDIO_STATICLIB
	)
endif()

target_compile_definitions(${LIBRARY_NAME}
	PUBLIC
		HAVE_CONFIG_H
	PRIVATE
		_CRT_SECURE_NO_WARNINGS
		_CRT_NONSTDC_NO_DEPRECATE
)

set_target_properties(${LIBRARY_NAME} PROPERTIES
	LINKER_LANGUAGE C
	C_STANDARD 99
	C_STANDARD_REQUIRED ON
)

if(LIBCDIO_ICONV_LIBRARY)
	target_link_libraries(${LIBRARY_NAME}
		PRIVATE
			${LIBCDIO_ICONV_LIBRARY}
	)
endif()

if(WIN32)
	target_link_libraries(${LIBRARY_NAME}
		PRIVATE
			winmm
	)
elseif(APPLE)
	find_library(IOKIT_FRAMEWORK NAMES IOKit)
	find_library(COREFOUNDATION_FRAMEWORK NAMES CoreFoundation)
	find_library(DISKARBITRATION_FRAMEWORK NAMES DiskArbitration)

	if(IOKIT_FRAMEWORK AND COREFOUNDATION_FRAMEWORK)
		target_link_libraries(${LIBRARY_NAME}
			PRIVATE
				${IOKIT_FRAMEWORK}
				${COREFOUNDATION_FRAMEWORK}
		)
	else()
		message(FATAL_ERROR "LibCDIO Darwin driver requires IOKit and CoreFoundation.")
	endif()

	if(DISKARBITRATION_FRAMEWORK AND HAVE_DISKARBITRATION)
		target_link_libraries(${LIBRARY_NAME}
			PRIVATE
				${DISKARBITRATION_FRAMEWORK}
		)
	endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
	find_library(CAM_LIBRARY cam)

	if(NOT CAM_LIBRARY)
		message(FATAL_ERROR "FreeBSD LibCDIO support requires LibCam.")
	endif()

	target_link_libraries(${LIBRARY_NAME}
		PRIVATE
			${CAM_LIBRARY}
	)
endif()

if(LIBCDIO_BUILD_CXX_WRAPPER)
	set(WRAPPER_HEADER_FILES
		include/cdio++/cdio.hpp
		include/cdio++/cdtext.hpp
		include/cdio++/device.hpp
		include/cdio++/devices.hpp
		include/cdio++/disc.hpp
		include/cdio++/enum.hpp
		include/cdio++/iso9660.hpp
		include/cdio++/mmc.hpp
		include/cdio++/read.hpp
		include/cdio++/track.hpp
	)

	set(WRAPPER_SOURCE_FILES
		lib/cdio++/cdio.cpp
		lib/cdio++/devices.cpp
		lib/cdio++/iso9660.cpp
	)

	add_library(${WRAPPER_NAME} ${WRAPPER_HEADER_FILES} ${WRAPPER_SOURCE_FILES})

	add_library(${PROJECT_NAME}::${WRAPPER_NAME} ALIAS ${WRAPPER_NAME})

	target_include_directories(${WRAPPER_NAME}
		PUBLIC
			$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
			$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
		PRIVATE
			${CMAKE_CURRENT_SOURCE_DIR}/include/cdio
			${CMAKE_CURRENT_SOURCE_DIR}/src
	)

	if(WIN32)
		target_include_directories(${WRAPPER_NAME}
			PRIVATE
				${CMAKE_CURRENT_SOURCE_DIR}/.vs
		)
	endif()

	set_target_properties(${WRAPPER_NAME} PROPERTIES
		CXX_STANDARD 11
		CXX_STANDARD_REQUIRED ON
	)

	target_link_libraries(${WRAPPER_NAME}
		PUBLIC
			${LIBRARY_NAME}
	)
endif()

include(GNUInstallDirs)

set(CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(VERSION_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
set(PROJECT_CONFIG "${GENERATED_DIR}/${PROJECT_NAME}Config.cmake")
set(TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(NAMESPACE "${PROJECT_NAME}::")

include(CMakePackageConfigHelpers)

write_basic_package_version_file(
	"${VERSION_CONFIG}" COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
	"cmake/Config.cmake.in"
	"${PROJECT_CONFIG}"
	INSTALL_DESTINATION "${CONFIG_INSTALL_DIR}"
)

set(INSTALL_TARGETS
	${LIBRARY_NAME}
)

if(LIBCDIO_BUILD_CXX_WRAPPER)
	list(APPEND INSTALL_TARGETS
		${WRAPPER_NAME}
	)
endif()

install(
	TARGETS ${INSTALL_TARGETS}
	EXPORT "${TARGETS_EXPORT_NAME}"
	LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
	ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
	RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
	INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

install(
	FILES ${LIBRARY_HEADER_FILES}
	DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${LIBRARY_NAME}"
)

install(
	FILES ${SPECIAL_LIBRARY_HEADER_FILES}
	DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

if(LIBCDIO_BUILD_CXX_WRAPPER)
	install(
		FILES ${WRAPPER_HEADER_FILES}
		DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${WRAPPER_NAME}"
	)
endif()

install(
	FILES "${PROJECT_CONFIG}" "${VERSION_CONFIG}"
	DESTINATION "${CONFIG_INSTALL_DIR}"
)

install(
	EXPORT "${TARGETS_EXPORT_NAME}"
	NAMESPACE "${NAMESPACE}"
	DESTINATION "${CONFIG_INSTALL_DIR}"
)
