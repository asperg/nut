dnl Check for tools used in spell-checking of documentation source files.
dnl On success, set nut_have_aspell="yes" (meaning we can do at least some
dnl documentation checks) and lots of automake macros and configure vars.
dnl On failure, set nut_have_aspell="no" (meaning we can't run the checks).
dnl This macro can be run multiple times, but will do the checking only once.

AC_DEFUN([NUT_CHECK_ASPELL],
[
if test -z "${nut_have_aspell_seen}"; then
	nut_have_aspell_seen=yes

	dnl # Note: this is just a known-working version on NUT CI platforms:
	dnl # Legacy baselines (CentOS 7, OpenBSD 6.5):
	dnl # @(#) International Ispell Version 3.1.20 (but really Aspell 0.60.6.1)
	dnl # More recent distros (as of 2022-2023):
	dnl # @(#) International Ispell Version 3.1.20 (but really Aspell 0.60.8)
	ASPELL_MIN_VERSION="0.60.6"

	dnl check for spell checking deps
	AC_PATH_PROGS([ASPELL], [aspell])

	dnl Some builds of aspell (e.g. in mingw) claim they do not know mode "tex"
	dnl even though they can list it as a built-in filter and files exist.
	dnl It seems that specifying the path helps in those cases.
	ASPELL_FILTER_LIB_PATH="none"
	ASPELL_FILTER_SHARE_PATH="none"
	dnl Location of "tex.amf" may be shifted, especially if binary filters
	dnl are involved (happens in some platform packages but not others).
	ASPELL_FILTER_TEX_PATH="none"
	if test -n "${ASPELL}" ; then
		dnl # e.g.: @(#) International Ispell Version 3.1.20 (but really Aspell 0.60.8)
		AC_MSG_CHECKING([for aspell version])
		ASPELL_VERSION="`LANG=C LC_ALL=C ${ASPELL} --version 2>/dev/null | sed -e 's,^.*@<:@Aa@:>@spell \(@<:@0-9.@:>@*\),\1,' -e 's,@<:@^0-9.@:>@.*,,'`" || ASPELL_VERSION="none"
		AC_MSG_RESULT([${ASPELL_VERSION}])

		ASPELL_VERSION_MINMAJ="`echo "${ASPELL_VERSION}" | sed 's,\.@<:@0-9@:>@@<:@0-9@:>@*$,,'`"

		AC_MSG_CHECKING([for aspell "lib" filtering resources directory])
		ASPELL_BINDIR="`dirname "$ASPELL"`"
		if test -d "${ASPELL_BINDIR}/../lib" ; then
			if test x"${ASPELL_VERSION}" != x"none" && test -d "${ASPELL_BINDIR}/../lib/aspell-${ASPELL_VERSION}" ; then
				ASPELL_FILTER_LIB_PATH="`cd "${ASPELL_BINDIR}/../lib/aspell-${ASPELL_VERSION}" && pwd`" \
				|| ASPELL_FILTER_LIB_PATH="${ASPELL_BINDIR}/../lib/aspell-${ASPELL_VERSION}"
			else
				if test x"${ASPELL_VERSION_MINMAJ}" != x"none" && test -d "${ASPELL_BINDIR}/../lib/aspell-${ASPELL_VERSION_MINMAJ}" ; then
					ASPELL_FILTER_LIB_PATH="`cd "${ASPELL_BINDIR}/../lib/aspell-${ASPELL_VERSION_MINMAJ}" && pwd`" \
					|| ASPELL_FILTER_LIB_PATH="${ASPELL_BINDIR}/../lib/aspell-${ASPELL_VERSION_MINMAJ}"
				else
					if test -d "${ASPELL_BINDIR}/../lib/aspell" ; then
						ASPELL_FILTER_LIB_PATH="`cd "${ASPELL_BINDIR}/../lib/aspell" && pwd`" \
						|| ASPELL_FILTER_LIB_PATH="${ASPELL_BINDIR}/../lib/aspell"
					fi
				fi
			fi
		fi
		AC_MSG_RESULT([${ASPELL_FILTER_LIB_PATH}])

		AC_MSG_CHECKING([for aspell "share" filtering resources directory])
		ASPELL_BINDIR="`dirname "$ASPELL"`"
		if test -d "${ASPELL_BINDIR}/../share" ; then
			if test x"${ASPELL_VERSION}" != x"none" && test -d "${ASPELL_BINDIR}/../share/aspell-${ASPELL_VERSION}" ; then
				ASPELL_FILTER_SHARE_PATH="`cd "${ASPELL_BINDIR}/../share/aspell-${ASPELL_VERSION}" && pwd`" \
				|| ASPELL_FILTER_SHARE_PATH="${ASPELL_BINDIR}/../share/aspell-${ASPELL_VERSION}"
			else
				if test x"${ASPELL_VERSION_MINMAJ}" != x"none" && test -d "${ASPELL_BINDIR}/../share/aspell-${ASPELL_VERSION_MINMAJ}" ; then
					ASPELL_FILTER_SHARE_PATH="`cd "${ASPELL_BINDIR}/../share/aspell-${ASPELL_VERSION_MINMAJ}" && pwd`" \
					|| ASPELL_FILTER_SHARE_PATH="${ASPELL_BINDIR}/../share/aspell-${ASPELL_VERSION_MINMAJ}"
				else
					if test -d "${ASPELL_BINDIR}/../share/aspell" ; then
						ASPELL_FILTER_SHARE_PATH="`cd "${ASPELL_BINDIR}/../share/aspell" && pwd`" \
						|| ASPELL_FILTER_SHARE_PATH="${ASPELL_BINDIR}/../share/aspell"
					fi
				fi
			fi
		fi
		AC_MSG_RESULT([${ASPELL_FILTER_SHARE_PATH}])

		AC_MSG_CHECKING([for aspell "tex" filtering resources directory])
		dnl # May be in a platform-dependent subdir (e.g. Debian Linux)
		dnl # or not (e.g. MinGW/MSYS2, OpenIndiana):
		if test -d "${ASPELL_FILTER_LIB_PATH}" ; then
			ASPELL_FILTER_TEX_PATH="`find "${ASPELL_FILTER_LIB_PATH}" -name "tex.amf"`" \
			&& test x"${ASPELL_FILTER_TEX_PATH}" != x \
			&& ASPELL_FILTER_TEX_PATH="`dirname "${ASPELL_FILTER_TEX_PATH}"`" \
			&& test -d "${ASPELL_FILTER_TEX_PATH}" \
			|| ASPELL_FILTER_TEX_PATH="none"
		fi
		dnl # Fallback (e.g. on FreeBSD):
		if test x"${ASPELL_FILTER_TEX_PATH}" = xnone \
		&& test -d "${ASPELL_FILTER_SHARE_PATH}" ; then
			ASPELL_FILTER_TEX_PATH="`find "${ASPELL_FILTER_SHARE_PATH}" -name "tex.amf"`" \
			&& test x"${ASPELL_FILTER_TEX_PATH}" != x \
			&& ASPELL_FILTER_TEX_PATH="`dirname "${ASPELL_FILTER_TEX_PATH}"`" \
			&& test -d "${ASPELL_FILTER_TEX_PATH}" \
			|| ASPELL_FILTER_TEX_PATH="none"
		fi

		AC_MSG_RESULT([${ASPELL_FILTER_TEX_PATH}])
	fi
	AM_CONDITIONAL([HAVE_ASPELL_FILTER_LIB_PATH], [test -d "$ASPELL_FILTER_LIB_PATH"])
	AC_SUBST(ASPELL_FILTER_LIB_PATH)
	AM_CONDITIONAL([HAVE_ASPELL_FILTER_SHARE_PATH], [test -d "$ASPELL_FILTER_SHARE_PATH"])
	AC_SUBST(ASPELL_FILTER_SHARE_PATH)
	AM_CONDITIONAL([HAVE_ASPELL_FILTER_TEX_PATH], [test -d "$ASPELL_FILTER_TEX_PATH"])
	AC_SUBST(ASPELL_FILTER_TEX_PATH)

	AC_MSG_CHECKING([if aspell version can do our documentation spell checks (minimum required ${ASPELL_MIN_VERSION})])
	AX_COMPARE_VERSION([${ASPELL_VERSION}], [ge], [${ASPELL_MIN_VERSION}], [
		AC_MSG_RESULT(yes)
		nut_have_aspell="yes"
	], [
		AC_MSG_RESULT(no)
		nut_have_aspell="no"
	])

	dnl Notes: we also keep HAVE_ASPELL for implicit targets, such as
	dnl addition to "make check" target
	dnl ### AM_CONDITIONAL([HAVE_ASPELL], [test -n "$ASPELL"])
	AM_CONDITIONAL([HAVE_ASPELL], [test "${nut_have_aspell}" = "yes"])

	AC_MSG_CHECKING([if we have all the tools mandatory for documentation spell checks])
	AC_MSG_RESULT([${nut_have_aspell}])
fi
])
