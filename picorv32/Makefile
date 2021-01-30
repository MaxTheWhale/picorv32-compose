TOOLCHAIN_PREFIX = riscv32-unknown-elf-

ICE40_SIM_CELLS=$(shell yosys-config --datdir/ice40/cells_sim.v)

all: top.bin

## -------------------
## firmware generation

firmware.elf: init.S main.c uart.c firmware.lds
	$(TOOLCHAIN_PREFIX)gcc \
		-march=rv32i -Os -ffreestanding -nostdlib \
		-o $@ init.S main.c uart.c \
		--std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,firmware.map,--strip-debug
	chmod -x $@

firmware.bin: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware.hex: firmware.bin
	python3 makehex.py $< 1792 > $@

## ------------------------------
## main flow: synth/p&r/bitstream

synth.json: top.v picorv32.v firmware.hex
	yosys -v3 -l synth.log -p 'synth_ice40 -top top -json $@; write_verilog -attr2comment synth.v' $(filter %.v, $^)

top.asc: synth.json top.pcf
	nextpnr-ice40 --hx8k --package cb132 --json $< --pcf top.pcf --asc $@

top.bin: top.asc
	icepack $< $@

## ------
## el fin

clean:
	rm -f firmware.elf firmware.map firmware.bin firmware.hex
	rm -f synth.log synth.v synth.json route.v top.asc top.bin
	rm -f example_tb.vvp synth_tb.vvp route_tb.vvp top.vcd

.PHONY: all clean
