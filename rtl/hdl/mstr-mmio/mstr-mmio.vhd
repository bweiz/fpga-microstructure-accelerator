library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


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
    clk              : in  std_logic;
    rst              : in  std_logic; -- active-high

    address          : in  std_logic_vector(4 downto 0); -- word address
    avs_read         : in  std_logic;
    avs_write        : in  std_logic;
    avs_writedata    : in  std_logic_vector(31 downto 0);
    avs_readdata     : out std_logic_vector(31 downto 0);

    cfg_bucket_ns    : out std_logic_vector(31 downto 0);
    cfg_vwap_t_ns    : out std_logic_vector(31 downto 0);
    cfg_mp_frac_bits : out std_logic_vector(7 downto 0);
    run_enable       : out std_logic;
    soft_reset_pulse : out std_logic
  );
end entity mstr_mmio;

architecture rtl of mstr_mmio is

  constant ID_CONST         : std_logic_vector(31 downto 0) := x"4D535452"; -- "MSTR"
  constant VERSION_CONST    : std_logic_vector(31 downto 0) := x"00010000"; -- 1.0

  signal r_run_enable       : std_logic;
  signal r_pulse_reset      : std_logic;
  signal r_bucket_ns        : std_logic_vector(31 downto 0);
  signal r_vwap_t_ns        : std_logic_vector(31 downto 0);
  signal r_mp_frac_bits     : std_logic_vector(7 downto 0);

  signal addr_i             : integer range 0 to 31;


  signal wr_en              : std_logic;
  signal wr_addr            : integer range 0 to 31;
  signal wr_data            : std_logic_vector(31 downto 0);

  signal e_status_running   : std_logic;
  signal e_status_error     : std_logic;
  signal e_status_init_done : std_logic;
  signal e_buckets_out_lo   : std_logic_vector(31 downto 0);
  signal status_word        : std_logic_vector(31 downto 0);
  signal buckets_out_lo     : std_logic_vector(31 downto 0);

begin

  addr_i <= to_integer(unsigned(address));
  wr_addr <= addr_i;

  wr_en   <= avs_write;

  wr_data <= avs_writedata;

  u_regs : entity work.mstr_regs
    port map (
    clk               => clk,
    rst               => rst,
    wr_en             => wr_en,
    wr_addr           => wr_addr,
    wr_data           => wr_data,
    cfg_bucket_ns     => r_bucket_ns,
    cfg_vwap_t_ns     => r_vwap_t_ns,
    cfg_mp_frac_bits  => r_mp_frac_bits,
    run_enable        => r_run_enable,
    soft_reset_pulse  => r_pulse_reset
  );

  u_engine : entity work.mstr_engine_v0
    port map (
    clk               => clk,
    rst               => rst,
    run_enable        => r_run_enable,
    soft_pulse_reset  => r_pulse_reset,
    cfg_bucket_ns     => r_bucket_ns,
    status_running    => e_status_running,
    status_error      => e_status_error,
    status_init_done  => e_status_init_done,
    buckets_out_lo    => e_buckets_out_lo
    );

  cfg_bucket_ns      <= r_bucket_ns;
  cfg_vwap_t_ns      <= r_vwap_t_ns;
  cfg_mp_frac_bits   <= r_mp_frac_bits;
  run_enable         <= r_run_enable;
  soft_reset_pulse   <= r_pulse_reset;

  status_word        <= (31 downto 3 => '0')
                        & e_status_init_done
                        & e_status_error
                        & e_status_running;

  buckets_out_lo     <= e_buckets_out_lo;
  -----------------------------------------------------------------------------
  -- READ path
  -----------------------------------------------------------------------------

  process(clk, rst)
    variable rd : std_logic_vector(31 downto 0);
  begin
    if rst = '1' then
      avs_readdata <= (others => '0');
    elsif rising_edge(clk) then
      rd := (others => '0');

      if avs_read = '1' then
        case addr_i is
          when 0 => rd := ID_CONST;
          when 1 => rd := VERSION_CONST;
          when 2 => rd := (31 downto 1 => '0') & r_run_enable; -- CTRL readback
          when 3 => rd := status_word;
          when 4 => rd := r_bucket_ns;
          when 5 => rd := r_vwap_t_ns;
          when 6 => rd := (31 downto 8 => '0') & r_mp_frac_bits;
          when 19 => rd := buckets_out_lo;
          when others => rd := (others => '0');
        end case;
      end if;

      avs_readdata <= rd;
    end if;
  end process;


end architecture rtl;
