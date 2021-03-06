AS=scas
CC=kcc

SDK_DIR=../zenith80-libc

_P=-Wp,-include -Wp,

include $(SDK_DIR)/flags.make

ASFLAGS=-fexplicit-export -fexplicit-import -Iheaders -I$(SDK_DIR)/include
CFLAGS=--nostdinc --nostdlib -Iheaders -I$(SDK_DIR)/include --no-std-crt0 --std-sdcc99 -mz80 $(addprefix $(_P),$(STD_INCLUDES))

STARTUP_SOURCES=$(addprefix startup/,rise.c)
MAIN_SOURCES=screens.c data.c icon.asm
SCREEN_SOURCES=$(addprefix screens/,main_menu.c intro_screen.c awaken.c to_your_feet.c cell.c examine_cookie.c self_head_bash.c break_cookie.c head_bash_escape.c prison_navigate.c)
SOURCES=$(addprefix src/,$(STARTUP_SOURCES) $(IO_SOURCES) $(MAIN_SOURCES) $(SCREEN_SOURCES) $(FP_SOURCES))
OBJECTS=$(addprefix bin/,$(addsuffix .o,$(basename $(SOURCES))))

bin/src/%.o:src/%.asm headers
	mkdir $(dir $@) -p
	$(AS) -c $< -o $@ $(ASFLAGS)
	
bin/src/%.o:src/%.c headers
	mkdir $(dir $@) -p
	$(CC) -S $< -o $(basename $@).asm $(CFLAGS)
	$(AS) -c $(basename $@).asm -o $@ $(ASFLAGS)
#	rm $(basename $@).asm

ROM=bin/rise.bin
IMAGE=bin/rise.png

.PHONY: .default all burn from_disk run debug
.default: $(ROM)

$(ROM): $(SDK_DIR)/bin/libc.o $(OBJECTS)
	scas $^ -o $@ $(ASFLAGS)

$(IMAGE): $(ROM)
	cat src/icon.png $(ROM) > $(IMAGE)

clean:
	$(RM) $(ROM) $(OBJECTS) $(LINKER) $(IMAGE)
	find bin/ -mindepth 2 -type f -delete

run: $(IMAGE)
	zenith80 --file $(IMAGE) --format=png

debug: $(IMAGE)
	zenith80-superdebug --file $(IMAGE) --format=png 2>o
	geany o
	rm o
	
burn: $(IMAGE)
	dd if=$(IMAGE) of=/dev/sdb

from_disk:
	zenith80 --file /dev/sdb --real --wait --format=png
