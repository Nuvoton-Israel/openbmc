EXE     = oom-test
CFILE  = *.c
DEPPKGS = gio-unix-2.0 glib-2.0
CC      ?= $(CROSS_COMPILE)g++
CFLAGS += $(shell pkg-config --cflags $(DEPPKGS))
CFLAGS += -std=c++1z
LIBS += $(shell pkg-config --libs $(LIBPKGS))
LIBS += -fPIC

all: $(EXE)
$(EXE): $(CFILE)
	$(CC) -g  $(CFLAGS) $(INCLUDES) -o $@ $^ -lstdc++ $(LIBS)

clean:
	rm -f $(EXE) *.o *.d
