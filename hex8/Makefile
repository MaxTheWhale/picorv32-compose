PROJ = hex8

FILES = test.v

.PHONY: iceFUN clean burn

iceFUN:
	# verilator --lint-only -Wall $(FILES)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top test -json $(PROJ).json" $(FILES)
	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf iceFUN.pcf

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

burn:
	iceFUNprog -v $(PROJ).bin

clean:
	rm *.asc *.bin *blif
