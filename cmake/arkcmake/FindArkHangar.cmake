# - Try to find  ArkHangar
# Once done, this will define
#
#  ARKHANGAR_FOUND        : library found
#  ARKHANGAR_DATADIR      : data directory 
#  ARKHANGAR_VERSION      : version

# macros
include(FindPackageHandleStandardArgs)

set(_ARKHANGAR_EXTRA_SEARCH_PATHS
    /usr/local
    /opt/local
    )

# find the data directory
find_path(ARKHANGAR_DATADIR
	NAMES arkhangar/config.h
    PATHS ${_ARKHANGAR_EXTRA_SEARCH_PATHS}
    PATH_SUFFIXES share
    )

# read the version
if (EXISTS ${ARKHANGAR_DATADIR}/arkhangar/config.h)
    file(READ ${ARKHANGAR_DATADIR}/arkhangar/config.h ARKHANGAR_VERSION_FILE)
    string(REGEX MATCH "#define ARKHANGAR_VERSION[ ]+\"(([0-9]+\\.)+[0-9]+)\""
        ARKHANGAR_VERSION_MATCH ${ARKHANGAR_VERSION_FILE})
    set(ARKHANGAR_VERSION ${CMAKE_MATCH_1})
else()
    set(ARKHANGAR_VERSION "")
endif()

# handle arguments
find_package_handle_standard_args(ArkHangar
    REQUIRED_VARS ARKHANGAR_DATADIR ARKHANGAR_VERSION
    VERSION_VAR ARKHANGAR_VERSION
    )
