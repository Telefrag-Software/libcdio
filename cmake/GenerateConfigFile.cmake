include(CheckIncludeFile)
include(CheckLibraryExists)
include(CheckFunctionExists)
include(CheckCSourceCompiles)
include(CheckStructHasMember)

check_include_file("alloca.h" HAVE_ALLOCA_H)
check_include_file("stdbool.h" HAVE_STDBOOL_H)
check_include_file("unistd.h" HAVE_UNISTD_H)
check_include_file("stdint.h" HAVE_STDINT_H)
check_include_file("errno.h" HAVE_ERRNO_H)
check_include_file("fcntl.h" HAVE_FCNTL_H)
check_include_file("glob.h" HAVE_GLOB_H)
check_include_file("memory.h" HAVE_MEMORY_H)
check_include_file("inttypes.h" HAVE_INTTYPES_H)
check_include_file("limits.h" HAVE_LIMITS_H)
check_include_file("stdio.h" HAVE_STDIO_H)
check_include_file("stdlib.h" HAVE_STDLIB_H)
check_include_file("string.h" HAVE_STRING_H)
check_include_file("strings.h" HAVE_STRINGS_H)
check_include_file("stdarg.h" HAVE_STDARG_H)
check_include_file("iconv.h" HAVE_ICONV_H)
check_include_file("sys/time.h" HAVE_SYS_TIME_H)
check_include_file("sys/stat.h" HAVE_SYS_STAT_H)
check_include_file("sys/types.h" HAVE_SYS_TYPES_H)
check_include_file("linux/cdrom.h" HAVE_LINUX_CDROM_H)
check_include_file("linux/version.h" HAVE_LINUX_VERSION_H)

if(HAVE_LINUX_CDROM_H AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
	set(HAVE_LINUX_CDROM 1)
endif()

check_function_exists(gettimeofday HAVE_GETTIMEOFDAY)
check_function_exists(memcpy HAVE_MEMCPY)
check_function_exists(memset HAVE_MEMSET)
check_function_exists(strndup HAVE_STRNDUP)
check_function_exists(snprintf HAVE_SNPRINTF)
check_function_exists(vsnprintf HAVE_VSNPRINTF)
check_function_exists(tzset HAVE_TZSET)
check_function_exists(alloca HAVE_ALLOCA)
check_function_exists(setenv HAVE_SETENV)
check_function_exists(unsetenv HAVE_UNSETENV)
check_function_exists(timegm HAVE_TIMEGM)
check_function_exists(gmtime_r HAVE_GMTIME_R)
check_function_exists(localtime_r HAVE_LOCALTIME_R)

check_struct_has_member("struct tm" tm_gmtoff "time.h" HAVE_TM_GMTOFF)
check_struct_has_member("struct tm" tm_zone "time.h" HAVE_STRUCT_TM_TM_ZONE)

check_library_exists(iconv iconv_open "" HAVE_ICONV_LIBICONV)
check_library_exists(c iconv_open "" HAVE_ICONV_LIBC)

if(HAVE_ICONV_H AND (HAVE_ICONV_LIBICONV OR HAVE_ICONV_LIBC))
	set(HAVE_ICONV 1)
else()
	set(HAVE_ICONV 0)
endif()

check_c_source_compiles("
#include <sys/stat.h>
int main() { return S_ISLNK(0); }
" HAVE_S_ISLNK)

check_c_source_compiles("
#include <sys/stat.h>
int main() { return S_ISSOCK(0); }
" HAVE_S_ISSOCK)

check_c_source_compiles("
#include <sys/time.h>
int main() { struct timespec ts; return 0; }
" HAVE_STRUCT_TIMESPEC)

check_c_source_compiles("
int main() { _Pragma(\"pack(1)\"); return 0; }
" HAVE_ISOC99_PRAGMA)

if(HAVE_LINUX_CDROM)
	check_c_source_compiles("
	#include <linux/cdrom.h>
	int main() {
		struct cdrom_generic_command c;
		return sizeof(c.timeout);
	}
	" HAVE_LINUX_CDROM_TIMEOUT)
endif()

check_c_source_compiles("
#include <time.h>
int main() { return timezone; }
" HAVE_TIMEZONE_VAR)

check_c_source_compiles("
#include <time.h>
int main() { return daylight; }
" HAVE_DAYLIGHT)

check_c_source_compiles("
#include <time.h>
int main() { return tzname != 0; }
" HAVE_TZNAME)

check_c_source_compiles("
struct { int a; int b[]; } x;
int main() { return 0; }
" EMPTY_ARRAY_UNSPECIFIED)

if(EMPTY_ARRAY_UNSPECIFIED)
	set(EMPTY_ARRAY_SIZE "")
else()
	check_c_source_compiles("
	struct { int a; int b[0]; } x;
	int main() { return 0; }
	" EMPTY_ARRAY_ZERO)

	if(EMPTY_ARRAY_ZERO)
		set(EMPTY_ARRAY_SIZE 0)
	else()
		message(FATAL_ERROR "No empty array support!")
	endif()
endif()

check_c_source_compiles("
#include <langinfo.h>
int main() {
	char *cs = nl_langinfo(CODESET);
	return (cs != 0);
}
" HAVE_LANGINFO_CODESET)

check_c_source_compiles("
#include <iconv.h>

int main() {
	iconv_t cd;
	const char *inbuf = 0;
	char *outbuf = 0;
	size_t inbytesleft = 0;
	size_t outbytesleft = 0;

	iconv(cd,
		(char **)&inbuf,
		&inbytesleft,
		&outbuf,
		&outbytesleft);
	return 0;
}
" ICONV_USES_CONST_BROKEN)

if(ICONV_USES_CONST_BROKEN)
	set(ICONV_CONST "")
else()
	set(ICONV_CONST "const")
endif()

set(HAVE_JOLIET ${LIBCDIO_ENABLE_JOLIET})
set(HAVE_ROCK ${LIBCDIO_ENABLE_ROCK})

set(_CDIO_VERSION_CONFIG_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/include/cdio/config.h")

configure_file(
	${_CDIO_VERSION_CONFIG_FILE_PATH}.in
	${_CDIO_VERSION_CONFIG_FILE_PATH}
	@ONLY
)

message(STATUS "Generated config file: '${_CDIO_VERSION_CONFIG_FILE_PATH}'.")
