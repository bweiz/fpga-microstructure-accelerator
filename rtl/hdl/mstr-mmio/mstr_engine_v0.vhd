library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mstr_engine_v0 is
  port (
    clk               : in  std_logic;
    rst               : in  std_logic;

    run_enable        : in  std_logic;
    soft_pulse_reset  : in  std_logic;

    -- NEW: direct cycle-domain bucket period (avoid divider)
    cfg_bucket_cycles : in  std_logic_vector(31 downto 0);

    snapshot_pulse    : in  std_logic;

    status_running    : out std_logic;
    status_error      : out std_logic;
    status_init_done  : out std_logic;

    -- NEW: live bucket tick + id for downstream logic
    bucket_tick       : out std_logic;
    bucket_id_lo      : out std_logic_vector(31 downto 0);

    -- Snapshot outputs
    buckets_out_lo        : out std_logic_vector(31 downto 0);
    cycles_running_lo     : out std_logic_vector(31 downto 0);
    last_bucket_cycles_lo : out std_logic_vector(31 downto 0);
    soft_reset_count_lo   : out std_logic_vector(31 downto 0)
  );
end entity;

architecture arch of mstr_engine_v0 is

  signal bucket_cycles_u32      : unsigned(31 downto 0);
  signal bucket_cycles_clamped  : unsigned(31 downto 0);

  signal cycle_count            : unsigned(31 downto 0);
  signal buckets_count_reg      : unsigned(31 downto 0);
  signal init_done_reg          : std_logic;

  -- Debug counters
  signal cycles_running_reg      : unsigned(31 downto 0);
  signal last_bucket_cycles_reg  : unsigned(31 downto 0);
  signal soft_reset_count_reg    : unsigned(31 downto 0);

  -- Snapshot regs
  signal buckets_snap_reg            : unsigned(31 downto 0);
  signal cycles_running_snap_reg     : unsigned(31 downto 0);
  signal last_bucket_cycles_snap_reg : unsigned(31 downto 0);
  signal soft_reset_count_snap_reg   : unsigned(31 downto 0);

  signal bucket_tick_reg         : std_logic;

begin

  bucket_cycles_u32 <= unsigned(cfg_bucket_cycles);

  -- Clamp bucket cycles to >= 1
  process(bucket_cycles_u32)
  begin
    if bucket_cycles_u32 = 0 then
      bucket_cycles_clamped <= to_unsigned(1, 32);
    else
      bucket_cycles_clamped <= bucket_cycles_u32;
    end if;
  end process;

  -- State update
  process(clk, rst)
  begin
    if rst = '1' then
      cycle_count               <= (others => '0');
      buckets_count_reg         <= (others => '0');
      init_done_reg             <= '0';

      cycles_running_reg        <= (others => '0');
      last_bucket_cycles_reg    <= (others => '0');
      soft_reset_count_reg      <= (others => '0');

      buckets_snap_reg          <= (others => '0');
      cycles_running_snap_reg   <= (others => '0');
      last_bucket_cycles_snap_reg <= (others => '0');
      soft_reset_count_snap_reg <= (others => '0');

      bucket_tick_reg           <= '0';

    elsif rising_edge(clk) then
      init_done_reg   <= '1';
      bucket_tick_reg <= '0';  -- default: deassert, pulse only on wrap

      if soft_pulse_reset = '1' then
        cycle_count            <= (others => '0');
        buckets_count_reg      <= (others => '0');

        cycles_running_reg     <= (others => '0');
        last_bucket_cycles_reg <= (others => '0');

        soft_reset_count_reg   <= soft_reset_count_reg + 1;

      elsif run_enable = '1' then
        cycles_running_reg <= cycles_running_reg + 1;

        if cycle_count = (bucket_cycles_clamped - 1) then
          cycle_count            <= (others => '0');
          buckets_count_reg      <= buckets_count_reg + 1;
          last_bucket_cycles_reg <= bucket_cycles_clamped;
          bucket_tick_reg        <= '1';
        else
          cycle_count <= cycle_count + 1;
        end if;

      else
        -- when not running, hold bucket counter, reset cycle counter
        cycle_count <= (others => '0');
      end if;

      -- Snapshot capture (for MMIO "atomic" reads)
      if snapshot_pulse = '1' then
        buckets_snap_reg            <= buckets_count_reg;
        cycles_running_snap_reg     <= cycles_running_reg;
        last_bucket_cycles_snap_reg <= last_bucket_cycles_reg;
        soft_reset_count_snap_reg   <= soft_reset_count_reg;
      end if;

    end if;
  end process;

  -- Status
  status_running   <= run_enable;
  status_error     <= '0';
  status_init_done <= init_done_reg;

  -- Live tick/id
  bucket_tick  <= bucket_tick_reg;
  bucket_id_lo <= std_logic_vector(buckets_count_reg);

  -- Snapshot outputs
  buckets_out_lo        <= std_logic_vector(buckets_snap_reg);
  cycles_running_lo     <= std_logic_vector(cycles_running_snap_reg);
  last_bucket_cycles_lo <= std_logic_vector(last_bucket_cycles_snap_reg);
  soft_reset_count_lo   <= std_logic_vector(soft_reset_count_snap_reg);

end architecture;
