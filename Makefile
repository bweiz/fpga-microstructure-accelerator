
# >>> VHDL_GHDL_BLOCK >>>
# Repo-root VHDL build (GHDL)
# Usage:
#   make lint
#   make clean

GHDL      := ghdl
STD       := 08
WORK      := work

MMIO_DIR  := rtl/hdl/mstr-mmio
BUILD_DIR := build/ghdl/mstr-mmio

# Ordered sources (packages first if you add any later)
VHDL_SRC := \
	$(MMIO_DIR)/mstr_regs.vhd \
	$(MMIO_DIR)/mstr_engine_v0.vhd \
	$(MMIO_DIR)/mstr-mmio.vhd

.PHONY: lint clean

lint:
	@mkdir -p $(BUILD_DIR)
	$(GHDL) -a --std=$(STD) --work=$(WORK) --workdir=$(BUILD_DIR) $(VHDL_SRC)

clean:
	rm -rf build
# <<< VHDL_GHDL_BLOCK <<<
