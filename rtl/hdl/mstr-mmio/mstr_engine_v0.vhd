library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mstr_engine_v0 is
  port (
         clk              : in std_logic;
         rst              : in std_logic;
         run_enable       : in std_logic;
         soft_pulse_reset : in std_logic;
         cfg_bucket_ns    : in std_logic_vector(31 downto 0);

         status_running   : out std_logic;
         status_error     : out std_logic;
         status_init_done : out std_logic;

         buckets_out_lo   : out std_logic_vector(31 downto 0)
  );
end entity;

architecture arch of mstr_engine_v0 is

begin

  status_running   <= run_enable;
  status_error     <= '0';
  status_init_done <= '1';
  buckets_out_lo   <= (others => '0');

end architecture arch;
