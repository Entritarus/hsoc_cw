CC:=gcc
CROSS_COMPILE:=arm-linux-gnueabihf-

CFLAGS:=-Wall -O2
LFLAGS:=-static
DEFINES?=

SRC:=$(shell find . -name "*.c")
OBJ:=$(subst src/,obj/,$(SRC))
OBJ:=$(subst .c,.o,$(OBJ))

OUT:=out/main.elf
DIR:=$(sort $(dir $(OBJ))) $(sort $(dir $(OUT)))
INC:=-Iinc -Ilib
LIB:=-Llib -lmsgdma -lcma -lm

all:$(DIR) $(OUT)

$(DIR):
	mkdir -p $@

$(OUT):$(OBJ)
	$(CROSS_COMPILE)$(CC) $(LFLAGS) $(OBJ) -o $(OUT) $(LIB)

obj/%.o: src/%.c
	$(CROSS_COMPILE)$(CC) $(CFLAGS) $(DEFINES) $(INC) -c -o $@ $<

clean:
	rm -fr $(DIR)
