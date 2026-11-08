SRC    = $(wildcard src/*.asm)
OBJ    = $(patsubst src/%.asm,build/%.o,$(SRC))
TARGET = asmshare

all: $(TARGET)

$(TARGET): $(OBJ)
	ld -o $@ $(OBJ)

build/%.o: src/%.asm include/syscalls.inc | build
	nasm -f elf64 -I . -o $@ $<

build:
	mkdir -p build

clean:
	rm -rf build $(TARGET)

run: all
	./$(TARGET)

.PHONY: all clean run
