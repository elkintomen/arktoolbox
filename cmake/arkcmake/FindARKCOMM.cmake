# - Try to find  ARKCOMM
# Once done, this will define
#
#  ARKCOMM_FOUND - system has scicoslab 
#  ARKCOMM_INCLUDE_DIRS - the scicoslab include directories
#  ARKCOMM_LIBRARIES - libraries to link to

include(LibFindMacros)
include(MacroCommonPaths)

MacroCommonPaths(ARKCOMM)

# Include dir
find_path(ARKCOMM_INCLUDE_DIR
	NAMES arkcomm/AsyncSerial.hpp
	PATHS ${COMMON_INCLUDE_PATHS_ARKCOMM}
)

# the library itself
find_library(ARKCOMM_LIBRARY
	NAMES arkcomm
	PATHS ${COMMON_LIBRARY_PATHS_ARKCOMM}
)

# the import file
find_path(ARKCOMM_LIBRARY_DIR
	NAMES arkcomm/arkcomm-targets.cmake
	PATHS ${COMMON_LIBRARY_PATHS_ARKCOMM}
)
set(ARKCOMM_LIB_IMPORT ${ARKCOMM_LIBRARY_DIR}/arkcomm/arkcomm-targets.cmake)

# Set the include dir variables and the libraries and let libfind_process do the rest.
# NOTE: Singular variables for this library, plural for libraries this this lib depends on.
set(ARKCOMM_PROCESS_INCLUDES ARKCOMM_INCLUDE_DIR)
set(ARKCOMM_PROCESS_LIBS ARKCOMM_LIBRARY ARKCOMM_LIBRARIES)
libfind_process(ARKCOMM)

macro(build_arkcomm TAG EP_BASE_DIR CMAKE_ARGS)
    list(APPEND CMAKE_ARGS "-DEP_BASE_DIR=${EP_BASE_DIR}")
    ExternalProject_Add(arkcomm
        GIT_REPOSITORY "git://github.com/arktools/arkcomm.git"
        GIT_TAG ${TAG}
        UPDATE_COMMAND ""
        INSTALL_DIR ${EP_BASE_DIR}/${CMAKE_INSTALL_PREFIX}
        CMAKE_ARGS ${CMAKE_ARGS}
        INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} DESTDIR=${EP_BASE_DIR} install
       )
endmacro()
