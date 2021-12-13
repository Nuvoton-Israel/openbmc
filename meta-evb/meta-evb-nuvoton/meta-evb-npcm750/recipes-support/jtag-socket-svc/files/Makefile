JTAG_SOCKET_SVC_SRCS := \
		src/socket_main.c \
		src/logging.c \
		src/handlers/SoftwareJTAGHandler.c \
		src/handlers/debug_enable.c \
		src/handlers/platform_reset.c \
		src/handlers/power_debug.c \
		src/handlers/power_good.c \
		src/handlers/prdy.c \
		src/handlers/preq.c \
		src/handlers/tck_mux_select.c \
		src/handlers/xdp_present.c \
		src/handlers/target_handler.c \

OBJS := $(JTAG_SOCKET_SVC_SRCS:.c=.o)

LIBS :=
LDFLAGS += -lpthread -lm
CFLAGS := -Iinclude

TARGET_JTAG_SOCKET_SVC := jtag_socket_svc
TARGET := $(TARGET_JTAG_SOCKET_SVC)

all: $(TARGET)

%.o : %.c
	$(CC) -c $< -o $@ ${LDFLAGS} ${CFLAGS} ${LIBS}

$(TARGET_JTAG_SOCKET_SVC): $(OBJS)
	$(CC) $(OBJS) -o $@ ${LIBS} ${LDFLAGS}

clean:
	rm -f *.o
