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

.PHONY: all clean run test


build/test_utils.o: tests/test_utils.asm include/syscalls.inc | build
	nasm -f elf64 -I . -o $@ $<

test: build/utils.o build/test_utils.o
	ld -o build/test_utils build/utils.o build/test_utils.o
	./build/test_utils
