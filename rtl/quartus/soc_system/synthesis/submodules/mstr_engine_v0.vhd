library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mstr_engine_v0 is
  port (
         clk                  : in std_logic;
         rst                  : in std_logic;
         run_enable           : in std_logic;
         soft_pulse_reset     : in std_logic;
         cfg_bucket_ns        : in std_logic_vector(31 downto 0);
			snapshot_pulse       : in std_logic;

         status_running       : out std_logic;
         status_error         : out std_logic;
         status_init_done     : out std_logic;

         buckets_out_lo       : out std_logic_vector(31 downto 0);
         cycles_running_lo    : out std_logic_vector(31 downto 0);
         last_bucket_cycles_lo : out std_logic_vector(31 downto 0);
         soft_reset_count_lo  : out std_logic_vector(31 downto 0)
  );
end entity;

architecture arch of mstr_engine_v0 is

  constant FCLK_HZ              : integer := 50_000_000;   -- 50 MHz clock
  constant NS_PER_SEC           : integer := 1_000_000_000;
  signal bucket_ns_u32          : unsigned(31 downto 0);
  signal fclk_u32					  : unsigned(31 downto 0);
  signal prod_u64					  : unsigned(63 downto 0);
  signal prod_u32 				  : unsigned(31 downto 0);
  signal cycles_u64             : unsigned(63 downto 0);   -- Avoid overflow
  signal bucket_cycles          : unsigned(31 downto 0);

  signal cycle_count            : unsigned(31 downto 0);
  signal buckets_count_reg      : unsigned(31 downto 0);
  signal init_done_reg          : std_logic;

  -- Debug counters
  signal cycles_running_reg     : unsigned(31 downto 0);
  signal last_bucket_cycles_reg : unsigned(31 downto 0);
  signal soft_reset_count_reg   : unsigned(31 downto 0);
  
  -- Snapshot regs
  signal buckets_snap_reg      : unsigned(31 downto 0);
  signal cycles_running_snap_reg : unsigned(31 downto 0);
  signal last_bucket_cycles_snap_reg : unsigned(31 downto 0);
  signal soft_reset_count_snap_reg   : unsigned(31 downto 0);
  
begin

  -- Convert and compute cycles
  bucket_ns_u32 <= unsigned(cfg_bucket_ns);
  fclk_u32      <= to_unsigned(FCLK_HZ, 32);


  prod_u64 <= resize(bucket_ns_u32 * fclk_u32, 64);
  cycles_u64    <= prod_u64 / to_unsigned(NS_PER_SEC, 64);

  -- Clamp bucket_cycles to >= 1
  process(cycles_u64)
  begin
    if cycles_u64 = 0 then
      bucket_cycles <= to_unsigned(1, 32);
    else
      bucket_cycles <= resize(cycles_u64, 32); -- take low 32 bits
    end if;
  end process;


  -- State Update
  process(clk, rst)
  begin

    if rst = '1' then
      cycle_count       <= (others => '0');
      buckets_count_reg <= (others => '0');
      init_done_reg     <= '0';
      cycles_running_reg <= (others => '0');
      last_bucket_cycles_reg <= (others => '0');
      soft_reset_count_reg <= (others => '0');
		
		buckets_snap_reg            <= (others => '0');
	   cycles_running_snap_reg     <= (others => '0');
		last_bucket_cycles_snap_reg <= (others => '0');
		soft_reset_count_snap_reg   <= (others => '0');

    elsif rising_edge(clk) then
      init_done_reg <= '1';

      if soft_pulse_reset = '1' then
        cycle_count       <= (others => '0');
        buckets_count_reg <= (others => '0');
        cycles_running_reg <= (others => '0');
        last_bucket_cycles_reg <= (others => '0');
        soft_reset_count_reg <= soft_reset_count_reg + 1;

      elsif run_enable = '1' then
        cycles_running_reg <= cycles_running_reg + 1;
        if cycle_count = bucket_cycles - 1 then
          cycle_count       <= (others => '0');
          buckets_count_reg <= buckets_count_reg + 1;
          last_bucket_cycles_reg <= bucket_cycles;

        else
          cycle_count <= cycle_count + 1;
        end if;

      else
        cycle_count <= (others => '0');
      end if;
		
		if snapshot_pulse  = '1' then
		  buckets_snap_reg            <= buckets_count_reg;
        cycles_running_snap_reg     <= cycles_running_reg;
        last_bucket_cycles_snap_reg <= last_bucket_cycles_reg;
        soft_reset_count_snap_reg   <= soft_reset_count_reg;
		 end if;
    end if;
  end process;

  status_running        <= run_enable;
  status_error          <= '0';
  status_init_done      <= init_done_reg;
  buckets_out_lo        <= std_logic_vector(buckets_snap_reg);
  cycles_running_lo     <= std_logic_vector(cycles_running_snap_reg);
  last_bucket_cycles_lo <= std_logic_vector(last_bucket_cycles_snap_reg);
  soft_reset_count_lo   <= std_logic_vector(soft_reset_count_snap_reg);

end architecture arch;
