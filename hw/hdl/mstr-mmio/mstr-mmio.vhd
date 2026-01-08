library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all
library std;
use std.standard;

-- Avalon-MM base address (HPS lightweight bridge):
--   Base: 0x0017F400
--   Span: 0x50 bytes (0x0017F400 - )
-- 32-bit register map (word offsets from base):
--   0x0 @ 0x0017F400: mmio register
--     Offset | Name | R/W | Reset | Description
--     ---:|---|:---:|---:|---
--     0x00 | `ID` | R | 0x4D535452 | ASCII `'MSTR'` (microstructure accel ID)
--     0x04 | `VERSION` | R | 0x0001_0000 | Major.Minor packed (example)
--
--   Control / Configuration
--     Offset | Name | R/W | Reset | Description
--     ---:|---|:---:|---:|---
--     0x08 | `CTRL` | R/W | 0x0000_0000 | bit0 START, bit1 STOP, bit2 RESET (see below)
--     0x0C | `STATUS` | R | 0x0000_0000 | bit0 RUNNING, bit1 ERROR, bit2 INIT_DONE (optional)
--     0x10 | `BUCKET_NS` | R/W | 1_000_000 | Bucket width in ns (default 1 ms)
--     0x14 | `VWAP_T_NS` | R/W | 0 | VWAP window in ns (0 = disabled until set)
--     0x18 | `MP_FRAC_BITS` | R/W | 8 | Microprice fractional bits (default 8)

entity mstr_mmio is
  port (
    clk                   : in std_logic;
    rst                   : in std_logic;
    address               : in std_logic_vector(4 downto 0);
    avs_read              : in std_logic;
    avs_write             : in std_logic;
    avs_writedata         : in std_logic_vector(31 downto 0);
    avs_readdata          : out std_logic_vector(31 downto 0);
    byteenable            : in std_logic_vector(3 downto 0);
    cfg_bucket_ns         : out std_logic_vector(31 downto 0);
    cfg_vwap_t_ns         : out std_logic_vector(31 downto 0);
    cfg_mp_frac_bits      : out std_logic_vector(7 downto 0);
    run_enable            : out std_logic;
    soft_reset_pulse      : out std_logic
  );
end entity mstr_mmio;

architecture rtl of mstr_mmio is

  ID_CONST                : std_logic_vector(31 downto 0) := x"4D535452";
  VERSION_CONST           : std_logic_vector(31 downto 0) := x"00010000";
  signal reg_run_enable   : std_logic;
  signal reg_pulse_reset  : std_logic;
  -- Will change following to on reset behaviour, not := xxx
  signal reg_bucket_ns    : std_logic_vector(31 downto 0) := x"000F4240"; -- 1000000 hex
  signal reg_vwap_t_ns    : std_logic_vector(31 downto 0) := (others => '0');
  signal reg_mp_frac_bits : std_logic_vector(7 downto 0) := x"08";

begin



end architecture rtl;
