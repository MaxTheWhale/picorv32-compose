TOOLCHAIN_PREFIX = riscv32-unknown-elf-

C_SOURCE_DIR = src
RTL_SOURCE_DIR = rtl
BUILD_DIR = build
FIRMWARE = '"$(BUILD_DIR)/firmware.hex"'

MEM_SIZE = 8192
STACK_SIZE = 256

multicore: $(BUILD_DIR)/multicore.bin

singlecore: $(BUILD_DIR)/singlecore.bin

## -------------------
## firmware generation

$(BUILD_DIR)/firmware.elf: $(C_SOURCE_DIR)/*.c $(C_SOURCE_DIR)/*.S firmware.lds
	$(TOOLCHAIN_PREFIX)gcc \
		-march=rv32i -Os -ffreestanding -nostdlib -DMEM_SIZE=$(MEM_SIZE) -DSTACK_SIZE=$(STACK_SIZE) \
		-o $@ $(filter %.c, $^) $(filter %.S, $^) \
		--std=gnu99 -lgcc -Wl,-Bstatic,-T,firmware.lds,--strip-debug
	chmod -x $@

$(BUILD_DIR)/firmware.bin: $(BUILD_DIR)/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

$(BUILD_DIR)/firmware.hex: $(BUILD_DIR)/firmware.bin
	python3 makehex.py $< 1792 > $@

## ------------------------------
## main flow: synth/p&r/bitstream

$(BUILD_DIR)/multicore.json: $(RTL_SOURCE_DIR)/multicore.v $(RTL_SOURCE_DIR)/picorv32.v $(BUILD_DIR)/firmware.hex
	yosys -DFIRMWARE=$(FIRMWARE) -DMEM_SIZE=$(MEM_SIZE) -v3 -p 'synth_ice40 -top top -json $@' $(filter %.v, $^)

$(BUILD_DIR)/multicore.asc: $(BUILD_DIR)/multicore.json top.pcf
	nextpnr-ice40 --hx8k --package cb132 --json $< --pcf top.pcf --asc $@

$(BUILD_DIR)/multicore.bin: $(BUILD_DIR)/multicore.asc
	icepack $< $@

$(BUILD_DIR)/singlecore.json: $(RTL_SOURCE_DIR)/singlecore.v $(RTL_SOURCE_DIR)/picorv32.v $(BUILD_DIR)/firmware.hex
	yosys -DFIRMWARE=$(FIRMWARE) -DMEM_SIZE=$(MEM_SIZE) -v3 -p 'synth_ice40 -top top -json $@' $(filter %.v, $^)

$(BUILD_DIR)/singlecore.asc: $(BUILD_DIR)/singlecore.json top.pcf
	nextpnr-ice40 --hx8k --package cb132 --json $< --pcf top.pcf --asc $@

$(BUILD_DIR)/singlecore.bin: $(BUILD_DIR)/singlecore.asc
	icepack $< $@

## ------
## el fin

clean:
	@rm -f $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.hex $(BUILD_DIR)/*.elf $(BUILD_DIR)/*.asc $(BUILD_DIR)/*.json

.PHONY: clean
