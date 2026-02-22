library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- mstr_regs: register file + CTRL semantics (no Avalon/MMIO bus logic here)
--
-- Word addresses (0..31) matching your current map:
--   2: CTRL
--   4: BUCKET_CYCLES   (replaces BUCKET_NS)
--   5: VWAP_T_NS
--   6: MP_FRAC_BITS
--   7: SNAPSHOT

entity mstr_regs is
  port (
    clk              : in  std_logic;
    rst              : in  std_logic;

    -- "Write transaction" interface coming from Avalon wrapper
    wr_en            : in  std_logic;
    wr_addr          : in  integer range 0 to 31;
    wr_data          : in  std_logic_vector(31 downto 0);

    -- Config outputs
    cfg_bucket_cycles : out std_logic_vector(31 downto 0);
    cfg_vwap_t_ns     : out std_logic_vector(31 downto 0);
    cfg_mp_frac_bits  : out std_logic_vector(7 downto 0);

    -- Control-plane outputs
    run_enable       : out std_logic;
    soft_reset_pulse : out std_logic;
    snapshot_pulse   : out std_logic
  );
end entity mstr_regs;

architecture rtl of mstr_regs is
  signal reg_bucket_cycles  : std_logic_vector(31 downto 0);
  signal reg_vwap_t_ns      : std_logic_vector(31 downto 0);
  signal reg_mp_frac_bits   : std_logic_vector(7 downto 0);

  signal reg_run_enable     : std_logic;
  signal reg_reset_pulse    : std_logic;
  signal reg_snapshot_pulse : std_logic;
begin

  -- Drive outputs (regs are the source of truth)
  cfg_bucket_cycles <= reg_bucket_cycles;
  cfg_vwap_t_ns     <= reg_vwap_t_ns;
  cfg_mp_frac_bits  <= reg_mp_frac_bits;

  run_enable        <= reg_run_enable;
  soft_reset_pulse  <= reg_reset_pulse;
  snapshot_pulse    <= reg_snapshot_pulse;

  -----------------------------------------------------------------------------
  -- Register update process
  -----------------------------------------------------------------------------
  process(clk, rst)
  begin
    if rst = '1' then
      -- Reset defaults
      -- 50 MHz clock => 20 ns/cycle. 1 ms = 50,000 cycles = 0x0000C350.
      reg_bucket_cycles <= x"0000C350";
      reg_vwap_t_ns     <= (others => '0');
      reg_mp_frac_bits  <= x"08";

      reg_run_enable    <= '0';
      reg_reset_pulse   <= '0';
      reg_snapshot_pulse<= '0';

    elsif rising_edge(clk) then
      -- self-clear the 1-cycle pulses
      reg_reset_pulse    <= '0';
      reg_snapshot_pulse <= '0';

      if wr_en = '1' then
        case wr_addr is
          when 2 =>  -- CTRL: bit0 START, bit1 STOP, bit2 RESET
            -- Policy: RESET generates pulse and clears run_enable
            if wr_data(2) = '1' then
              reg_reset_pulse <= '1';
              reg_run_enable  <= '0';
            end if;

            if wr_data(0) = '1' then
              reg_run_enable <= '1';
            end if;

            if wr_data(1) = '1' then
              reg_run_enable <= '0';
            end if;

          when 4 =>  -- BUCKET_CYCLES
            reg_bucket_cycles <= wr_data;

          when 5 =>  -- VWAP_T_NS
            reg_vwap_t_ns <= wr_data;

          when 6 =>  -- MP_FRAC_BITS
            reg_mp_frac_bits <= wr_data(7 downto 0);

          when 7 =>  -- SNAPSHOT
            if wr_data(0) = '1' then
              reg_snapshot_pulse <= '1';
            end if;

          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;
