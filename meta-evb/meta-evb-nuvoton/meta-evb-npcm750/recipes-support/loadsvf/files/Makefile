LOADSVF_SRCS := \
		src/main.c \
		src/jtag.c \
		src/svf.c \

OBJS := $(LOADSVF_SRCS:.c=.o)

LIBS :=
#LDFLAGS += -lpthread -lm
CFLAGS := -Iinclude -O2

TARGET_LOADSVF := loadsvf
TARGET := $(TARGET_LOADSVF)

all: $(TARGET)

%.o : %.c
	$(CC) -c $< -o $@ ${LDFLAGS} ${CFLAGS} ${LIBS}

$(TARGET_LOADSVF): $(OBJS)
	$(CC) $(OBJS) -o $@ ${LIBS} ${LDFLAGS}

clean:
	rm -f *.o
