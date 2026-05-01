# wminet_utils proxy DLL — see CLAUDE.md and src/ for context.
#
# This proxy works around a Roon 2.65+ crash caused by Wine's unimplemented
# wminet_utils.dll.GetErrorInfo. The proxy stubs GetErrorInfo as a no-op and
# forwards all other exports to a renamed copy of Wine's original DLL via the
# .def file.
#
# Usage:
#   make            # build wminet_utils.dll
#   make verify     # build and verify the result is a valid x86_64 PE32+ DLL
#   make clean      # remove build artifact

# Note: plain '=' (not '?=') because Make sets CC to 'cc' implicitly, which
# would otherwise win over '?='. Override on the command line: make CC=...
CC      := x86_64-w64-mingw32-gcc
DLL     := wminet_utils.dll
SRC     := src/wminet_utils_proxy.c
DEF     := src/wminet_utils.def

CFLAGS  := -O2 -Wall -Wextra
# --no-insert-timestamp makes builds bit-for-bit reproducible (PE timestamp
# field would otherwise change each build, even with identical inputs).
LDFLAGS := -shared -nostartfiles -Wl,--subsystem,windows,--no-insert-timestamp -lole32

.PHONY: all verify clean

all: $(DLL)

$(DLL): $(SRC) $(DEF)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC) $(DEF)

verify: $(DLL)
	@file $(DLL) | grep -q 'PE32+ executable.*x86-64' \
		|| { echo "ERROR: $(DLL) is not a valid x86_64 PE32+ DLL"; exit 1; }
	@echo "OK: $(DLL) is a valid x86_64 Windows DLL."

clean:
	rm -f $(DLL)
