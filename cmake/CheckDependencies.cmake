include_guard()

include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckIncludeFileCXX)
include(CheckLibraryExists)
include(CheckSymbolExists)
include(CheckTypeSize)
include(CheckStructHasMember)

check_c_source_compiles("
	#include <sys/types.h>
	#include <sys/stat.h>

	int main(void)
	{
		mode_t m = 0;
		(void)m;
		return 0;
	}
" HAVE_MODE_T)

set(EMPTY_ARRAY_SIZE "")

check_c_source_compiles("
	struct test
	{
		int foo;
		int bar[];
	} bar;

	int main(void)
	{
		(void)bar;
		return 0;
	}
" HAVE_FLEXIBLE_ARRAY_MEMBER)

if(NOT HAVE_FLEXIBLE_ARRAY_MEMBER)
	check_c_source_compiles("
		struct test {
			int foo;
			int bar[0];
		} bar;

		int main(void) {
			(void)bar;
			return 0;
		}
	" HAVE_ZERO_LENGTH_ARRAY)

	if(HAVE_ZERO_LENGTH_ARRAY)
		set(EMPTY_ARRAY_SIZE "0")
	else()
		message(FATAL_ERROR "Compiler is unable to create empty arrays.")
	endif()
endif()

function(check_headers)
	foreach(HEADER_FILE_NAME ${ARGN})
		string(MAKE_C_IDENTIFIER "${HEADER_FILE_NAME}" HEADER_FILE_IDENTIFIER)
		string(TOUPPER "${HEADER_FILE_IDENTIFIER}" HEADER_FILE_IDENTIFIER_UPPER_CASE)
		check_include_file("${HEADER_FILE_NAME}" "HAVE_${HEADER_FILE_IDENTIFIER_UPPER_CASE}")
	endforeach()
endfunction()

check_headers(
	alloca.h
	errno.h
	fcntl.h
	glob.h
	limits.h
	pwd.h
	stdarg.h
	stdbool.h
	stddef.h
	stdint.h
	stdio.h
	stdlib.h
	string.h
	strings.h
	sys/cdio.h
	sys/param.h
	sys/stat.h
	sys/time.h
	sys/timeb.h
	sys/types.h
	sys/utsname.h
	unistd.h
	getopt.h
	iconv.h
)

foreach(FUNCTION_NAME
	alloca
	chdir
	drand48
	fseeko
	fseeko64
	ftruncate
	geteuid
	getgid
	getuid
	getpwuid
	gettimeofday
	lseek64
	lstat
	memcpy
	memset
	mkstemp
	rand
	seteuid
	setegid
	snprintf
	setenv
	strndup
	unsetenv
	tzset
	sleep
	_stati64
	usleep
	vsnprintf
	readlink
	realpath
	gmtime_r
	localtime_r
	timegm
)
	string(TOUPPER "${FUNCTION_NAME}" FUNCTION_NAME_UPPER_CASE)
	check_function_exists("${FUNCTION_NAME}" "HAVE_${FUNCTION_NAME_UPPER_CASE}")
endforeach()

check_struct_has_member("struct tm" tm_gmtoff "time.h" HAVE_TM_GMTOFF)
check_struct_has_member("struct tm" tm_zone "time.h" HAVE_STRUCT_TM_TM_ZONE)

check_c_source_compiles("
	#include <sys/types.h>
	#include <sys/stat.h>

	int main(void)
	{
		return S_ISLNK(0);
	}
" HAVE_S_ISLNK)

check_c_source_compiles("
	#include <sys/types.h>
	#include <sys/stat.h>

	int main(void)
	{
		return S_ISSOCK(0);
	}
" HAVE_S_ISSOCK)

check_c_source_compiles("
	#include <time.h>

	int main(void)
	{
		return (timezone != 0) + daylight;
	}
" HAVE_DAYLIGHT)

check_c_source_compiles("
	#include <time.h>

	int main(void)
	{
		return tzname[0] != 0;
	}
" HAVE_TZNAME)

check_c_source_compiles("
	#include <sys/time.h>

	int main() {
		struct timespec ts;
		return 0;
	}
" HAVE_STRUCT_TIMESPEC)

check_c_source_compiles("
	#include <time.h>

	int main() {
		return timezone;
	}
" HAVE_TIMEZONE_VAR)

check_c_source_compiles("
	int main() {
		_Pragma(\"pack(1)\");
		return 0;
	}
" HAVE_ISOC99_PRAGMA)

check_c_source_compiles("
	#include <langinfo.h>

	int main() {
		char * codeSet = nl_langinfo(CODESET);
		return codeSet != 0;
	}
" HAVE_LANGINFO_CODESET)

if(HAVE_ICONV_H)
	set(ICONV_TEST_SOURCE "
		#include <iconv.h>

		int main(void)
		{
			iconv_t cd = iconv_open(\"UTF-8\", \"UTF-8\");
			if (cd == (iconv_t)-1)
				return 1;

			iconv_close(cd);
			return 0;
		}
	")

	check_c_source_compiles("${ICONV_TEST_SOURCE}" HAVE_ICONV)

	if(NOT HAVE_ICONV)
		check_library_exists(iconv iconv_open "" HAVE_LIBICONV)

		if(HAVE_LIBICONV)
			set(CMAKE_REQUIRED_LIBRARIES iconv)

			check_c_source_compiles("${ICONV_TEST_SOURCE}" HAVE_ICONV_WITH_LIBICONV)

			unset(CMAKE_REQUIRED_LIBRARIES)

			if(HAVE_ICONV_WITH_LIBICONV)
				set(HAVE_ICONV 1)
				set(LIBCDIO_ICONV_LIBRARY iconv)
			endif()
		endif()
	endif()
endif()

if(HAVE_ICONV)
	check_c_source_compiles("
		#include <stdlib.h>
		#include <iconv.h>

		int main(void)
		{
			size_t iconv(
				iconv_t cd,
				char ** inbuf,
				size_t * inbytesleft,
				char ** outbuf,
				size_t * outbytesleft
			);

			return 0;
		}
	" HAVE_ICONV_NONCONST)

	if(HAVE_ICONV_NONCONST)
		set(ICONV_CONST "")
	else()
		set(ICONV_CONST "const")
	endif()
else()
	set(ICONV_CONST "")
endif()

if(LIBCDIO_ENABLE_JOLIET)
	if(NOT HAVE_ICONV)
		message(FATAL_ERROR "'LIBCDIO_ENABLE_JOLIET' is enabled but IConv support was not detected. Consider disabling Joliet.")
	endif()

	set(HAVE_JOLIET 1)
endif()

if(LIBCDIO_ENABLE_ROCK)
	set(HAVE_ROCK 1)
endif()

if(WIN32)
	check_headers(
		windows.h
		ntddcdrm.h
		ddk/ntddcdrm.h
		ntddscsi.h
		ddk/ntddscsi.h
		ddk/scsi.h
	)
elseif(APPLE)
	check_include_file("IOKit/IOKitLib.h" HAVE_IOKIT_IOKITLIB_H)
	check_include_file("CoreFoundation/CFBase.h" HAVE_COREFOUNDATION_CFBASE_H)
	check_include_file("DiskArbitration/DiskArbitration.h" HAVE_DISKARBITRATION_H)

	find_library(DISKARBITRATION_FRAMEWORK NAMES DiskArbitration)

	if(DISKARBITRATION_FRAMEWORK)
		set(CMAKE_REQUIRED_LIBRARIES
			"${COREFOUNDATION_FRAMEWORK}"
			"${DISKARBITRATION_FRAMEWORK}"
		)

		check_c_source_compiles("
			#include <DiskArbitration/DiskArbitration.h>

			int main(void) {
				DASessionRef session = DASessionCreate(NULL);
				return session != NULL;
			}
		" HAVE_DISKARBITRATION)

		unset(CMAKE_REQUIRED_LIBRARIES)
	endif()
elseif(LINUX)
	check_include_file("linux/version.h" HAVE_LINUX_VERSION_H)
	check_include_file("linux/major.h" HAVE_LINUX_MAJOR_H)
	check_include_file("linux/cdrom.h" HAVE_LINUX_CDROM_H)

	if(HAVE_LINUX_CDROM_H)
		set(HAVE_LINUX_CDROM 1)

		check_c_source_compiles("
			#include <linux/cdrom.h>

			int main(void) {
				struct cdrom_generic_command command;
				(void)command.timeout;
				return 0;
			}
		" HAVE_LINUX_CDROM_TIMEOUT)
	endif()
endif()
