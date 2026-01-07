-- SPDX-License-Identifier: MIT
-- Copyright (c) 2025 Trevor Vannoy, Ross K. Snider.  All rights reserved.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity de10nano_top is
  port (
    ----------------------------------------
    --  Clock inputs
    --  See DE10 Nano User Manual page 23
    ----------------------------------------
    fpga_clk1_50 : in    std_ulogic;
    fpga_clk2_50 : in    std_ulogic;
    fpga_clk3_50 : in    std_ulogic;

    ----------------------------------------
    --  HDMI
    --  See DE10 Nano User Manual page 34
    ----------------------------------------
    hdmi_i2c_scl : inout std_logic;
    hdmi_i2c_sda : inout std_logic;
    hdmi_i2s     : inout std_logic;
    hdmi_lrclk   : inout std_logic;
    hdmi_mclk    : inout std_logic;
    hdmi_sclk    : inout std_logic;
    hdmi_tx_clk  : out   std_logic;
    hdmi_tx_d    : out   std_logic_vector(23 downto 0);
    hdmi_tx_de   : out   std_logic;
    hdmi_tx_hs   : out   std_logic;
    hdmi_tx_int  : in    std_logic;
    hdmi_tx_vs   : out   std_logic;

    ----------------------------------------
    --  DDR3
    --  See DE10 Nano User Manual page 39
    ----------------------------------------
    hps_ddr3_addr    : out   std_logic_vector(14 downto 0);
    hps_ddr3_ba      : out   std_logic_vector(2 downto 0);
    hps_ddr3_cas_n   : out   std_logic;
    hps_ddr3_ck_n    : out   std_logic;
    hps_ddr3_ck_p    : out   std_logic;
    hps_ddr3_cke     : out   std_logic;
    hps_ddr3_cs_n    : out   std_logic;
    hps_ddr3_dm      : out   std_logic_vector(3 downto 0);
    hps_ddr3_dq      : inout std_logic_vector(31 downto 0);
    hps_ddr3_dqs_n   : inout std_logic_vector(3 downto 0);
    hps_ddr3_dqs_p   : inout std_logic_vector(3 downto 0);
    hps_ddr3_odt     : out   std_logic;
    hps_ddr3_ras_n   : out   std_logic;
    hps_ddr3_reset_n : out   std_logic;
    hps_ddr3_rzq     : in    std_logic;
    hps_ddr3_we_n    : out   std_logic;

    ----------------------------------------
    --  Ethernet
    --  See DE10 Nano User Manual page 36
    ----------------------------------------
    hps_enet_gtx_clk : out   std_logic;
    hps_enet_int_n   : inout std_logic;
    hps_enet_mdc     : out   std_logic;
    hps_enet_mdio    : inout std_logic;
    hps_enet_rx_clk  : in    std_logic;
    hps_enet_rx_data : in    std_logic_vector(3 downto 0);
    hps_enet_rx_dv   : in    std_logic;
    hps_enet_tx_data : out   std_logic_vector(3 downto 0);
    hps_enet_tx_en   : out   std_logic;

    ----------------------------------------
    --  HPS i2c
    --  See DE10 Nano User Manual page 34
    ----------------------------------------
    hps_i2c1_sclk : inout std_logic;
    hps_i2c1_sdat : inout std_logic;

    ----------------------------------------
    --  HPS user I/O
    --  See DE10 Nano User Manual page 36
    ----------------------------------------
    hps_key : inout std_logic;
    hps_led : inout std_logic;

    ----------------------------------------
    --  HPS SD card
    --  See DE10 Nano User Manual page 42
    ----------------------------------------
    hps_sd_clk  : out   std_logic;
    hps_sd_cmd  : inout std_logic;
    hps_sd_data : inout std_logic_vector(3 downto 0);

    ----------------------------------------
    --  HPS UART
    --  See DE10 Nano User Manual page 38
    ----------------------------------------
    hps_uart_rx    : in    std_logic;
    hps_uart_tx    : out   std_logic;
    hps_conv_usb_n : inout std_logic;

    ----------------------------------------
    --  HPS USB OTG
    --  See DE10 Nano User Manual page 43
    ----------------------------------------
    hps_usb_clkout : in    std_logic;
    hps_usb_data   : inout std_logic_vector(7 downto 0);
    hps_usb_dir    : in    std_logic;
    hps_usb_nxt    : in    std_logic;
    hps_usb_stp    : out   std_logic;

    ----------------------------------------
    --  HPS accelerometer
    --  See DE10 Nano User Manual page 44
    ----------------------------------------
    hps_gsensor_int : inout std_logic;
    hps_i2c0_sclk   : inout std_logic;
    hps_i2c0_sdat   : inout std_logic;

    ----------------------------------------
    --  LTC connector
    --  See DE10 Nano User Manual page 45
    ----------------------------------------
    hps_ltc_gpio  : inout std_logic;
    hps_spim_clk  : out   std_logic;
    hps_spim_miso : in    std_logic;
    hps_spim_mosi : out   std_logic;
    hps_spim_ss   : inout std_logic;

    ----------------------------------------
    --  Push button inputs (KEY[0] and KEY[1])
    --  See DE10 Nano User Manual page 24
    --  The KEY push button inputs produce a '0'
    --  when pressed (asserted)
    --  and produce a '1' in the rest (non-pushed) state
    ----------------------------------------
    push_button_n : in    std_ulogic_vector(1 downto 0);

    ----------------------------------------
    --  Slide switch inputs (SW)
    --  See DE10 Nano User Manual page 25
    --  The slide switches produce a '0' when
    --  in the down position
    --  (towards the edge of the board)
    ----------------------------------------
    sw : in    std_ulogic_vector(3 downto 0);

    ----------------------------------------
    --  LED outputs
    --  See DE10 Nano User Manual page 26
    --  Setting LED to 1 will turn it on
    ----------------------------------------
    led : out   std_ulogic_vector(7 downto 0);

    ----------------------------------------
    --  GPIO expansion headers (40-pin)
    --  See DE10 Nano User Manual page 27
    --  Pin 11 = 5V supply (1A max)
    --  Pin 29 = 3.3 supply (1.5A max)
    --  Pins 12, 30 = GND
    ----------------------------------------
    gpio_0 : inout std_logic_vector(35 downto 0);
    gpio_1 : inout std_ulogic_vector(35 downto 0);

    ----------------------------------------
    --  Arudino headers
    --  See DE10 Nano User Manual page 30
    ----------------------------------------
    arduino_io      : inout std_ulogic_vector(15 downto 0);
    arduino_reset_n : inout std_ulogic;

    ----------------------------------------
    --  ADC header
    --  See DE10 Nano User Manual page 32
    ----------------------------------------
    adc_convst : inout std_ulogic;
    adc_sck    : out   std_ulogic;
    adc_sdi    : out   std_ulogic;
    adc_sdo    : in    std_ulogic
  );
end entity de10nano_top;

architecture de10nano_arch of de10nano_top is



  component soc_system is
    port (
      hps_io_hps_io_emac1_inst_tx_clk : out   std_logic;
      hps_io_hps_io_emac1_inst_txd0   : out   std_logic;
      hps_io_hps_io_emac1_inst_txd1   : out   std_logic;
      hps_io_hps_io_emac1_inst_txd2   : out   std_logic;
      hps_io_hps_io_emac1_inst_txd3   : out   std_logic;
      hps_io_hps_io_emac1_inst_rxd0   : in    std_logic;
      hps_io_hps_io_emac1_inst_mdio   : inout std_logic;
      hps_io_hps_io_emac1_inst_mdc    : out   std_logic;
      hps_io_hps_io_emac1_inst_rx_ctl : in    std_logic;
      hps_io_hps_io_emac1_inst_tx_ctl : out   std_logic;
      hps_io_hps_io_emac1_inst_rx_clk : in    std_logic;
      hps_io_hps_io_emac1_inst_rxd1   : in    std_logic;
      hps_io_hps_io_emac1_inst_rxd2   : in    std_logic;
      hps_io_hps_io_emac1_inst_rxd3   : in    std_logic;
      hps_io_hps_io_sdio_inst_cmd     : inout std_logic;
      hps_io_hps_io_sdio_inst_d0      : inout std_logic;
      hps_io_hps_io_sdio_inst_d1      : inout std_logic;
      hps_io_hps_io_sdio_inst_clk     : out   std_logic;
      hps_io_hps_io_sdio_inst_d2      : inout std_logic;
      hps_io_hps_io_sdio_inst_d3      : inout std_logic;
      hps_io_hps_io_usb1_inst_d0      : inout std_logic;
      hps_io_hps_io_usb1_inst_d1      : inout std_logic;
      hps_io_hps_io_usb1_inst_d2      : inout std_logic;
      hps_io_hps_io_usb1_inst_d3      : inout std_logic;
      hps_io_hps_io_usb1_inst_d4      : inout std_logic;
      hps_io_hps_io_usb1_inst_d5      : inout std_logic;
      hps_io_hps_io_usb1_inst_d6      : inout std_logic;
      hps_io_hps_io_usb1_inst_d7      : inout std_logic;
      hps_io_hps_io_usb1_inst_clk     : in    std_logic;
      hps_io_hps_io_usb1_inst_stp     : out   std_logic;
      hps_io_hps_io_usb1_inst_dir     : in    std_logic;
      hps_io_hps_io_usb1_inst_nxt     : in    std_logic;
      hps_io_hps_io_spim1_inst_clk    : out   std_logic;
      hps_io_hps_io_spim1_inst_mosi   : out   std_logic;
      hps_io_hps_io_spim1_inst_miso   : in    std_logic;
      hps_io_hps_io_spim1_inst_ss0    : out   std_logic;
      hps_io_hps_io_uart0_inst_rx     : in    std_logic;
      hps_io_hps_io_uart0_inst_tx     : out   std_logic;
      hps_io_hps_io_i2c0_inst_sda     : inout std_logic;
      hps_io_hps_io_i2c0_inst_scl     : inout std_logic;
      hps_io_hps_io_i2c1_inst_sda     : inout std_logic;
      hps_io_hps_io_i2c1_inst_scl     : inout std_logic;
      hps_io_hps_io_gpio_inst_gpio09  : inout std_logic;
      hps_io_hps_io_gpio_inst_gpio35  : inout std_logic;
      hps_io_hps_io_gpio_inst_gpio40  : inout std_logic;
      hps_io_hps_io_gpio_inst_gpio53  : inout std_logic;
      hps_io_hps_io_gpio_inst_gpio54  : inout std_logic;
      hps_io_hps_io_gpio_inst_gpio61  : inout std_logic;
      memory_mem_a                    : out   std_logic_vector(14 downto 0);
      memory_mem_ba                   : out   std_logic_vector(2 downto 0);
      memory_mem_ck                   : out   std_logic;
      memory_mem_ck_n                 : out   std_logic;
      memory_mem_cke                  : out   std_logic;
      memory_mem_cs_n                 : out   std_logic;
      memory_mem_ras_n                : out   std_logic;
      memory_mem_cas_n                : out   std_logic;
      memory_mem_we_n                 : out   std_logic;
      memory_mem_reset_n              : out   std_logic;
      memory_mem_dq                   : inout std_logic_vector(31 downto 0);
      memory_mem_dqs                  : inout std_logic_vector(3 downto 0);
      memory_mem_dqs_n                : inout std_logic_vector(3 downto 0);
      memory_mem_odt                  : out   std_logic;
      memory_mem_dm                   : out   std_logic_vector(3 downto 0);
      memory_oct_rzqin                : in    std_logic;
      clk_clk                         : in    std_logic;
      reset_reset_n                   : in    std_logic;
      mstr_mmio_tmp_external_connection_export : out   std_logic_vector(31 downto 0)
    );
  end component soc_system;

  signal rst_n : std_ulogic;

begin

  rst_n <= push_button_n(0);

  u0 : component soc_system
    port map (
      -- ethernet
      hps_io_hps_io_emac1_inst_tx_clk => hps_enet_gtx_clk,
      hps_io_hps_io_emac1_inst_txd0   => hps_enet_tx_data(0),
      hps_io_hps_io_emac1_inst_txd1   => hps_enet_tx_data(1),
      hps_io_hps_io_emac1_inst_txd2   => hps_enet_tx_data(2),
      hps_io_hps_io_emac1_inst_txd3   => hps_enet_tx_data(3),
      hps_io_hps_io_emac1_inst_mdio   => hps_enet_mdio,
      hps_io_hps_io_emac1_inst_mdc    => hps_enet_mdc,
      hps_io_hps_io_emac1_inst_rx_ctl => hps_enet_rx_dv,
      hps_io_hps_io_emac1_inst_tx_ctl => hps_enet_tx_en,
      hps_io_hps_io_emac1_inst_rx_clk => hps_enet_rx_clk,
      hps_io_hps_io_emac1_inst_rxd0   => hps_enet_rx_data(0),
      hps_io_hps_io_emac1_inst_rxd1   => hps_enet_rx_data(1),
      hps_io_hps_io_emac1_inst_rxd2   => hps_enet_rx_data(2),
      hps_io_hps_io_emac1_inst_rxd3   => hps_enet_rx_data(3),
      hps_io_hps_io_gpio_inst_gpio35  => hps_enet_int_n,

      -- sd card
      hps_io_hps_io_sdio_inst_cmd => hps_sd_cmd,
      hps_io_hps_io_sdio_inst_clk => hps_sd_clk,
      hps_io_hps_io_sdio_inst_d0  => hps_sd_data(0),
      hps_io_hps_io_sdio_inst_d1  => hps_sd_data(1),
      hps_io_hps_io_sdio_inst_d2  => hps_sd_data(2),
      hps_io_hps_io_sdio_inst_d3  => hps_sd_data(3),

      -- usb
      hps_io_hps_io_usb1_inst_d0  => hps_usb_data(0),
      hps_io_hps_io_usb1_inst_d1  => hps_usb_data(1),
      hps_io_hps_io_usb1_inst_d2  => hps_usb_data(2),
      hps_io_hps_io_usb1_inst_d3  => hps_usb_data(3),
      hps_io_hps_io_usb1_inst_d4  => hps_usb_data(4),
      hps_io_hps_io_usb1_inst_d5  => hps_usb_data(5),
      hps_io_hps_io_usb1_inst_d6  => hps_usb_data(6),
      hps_io_hps_io_usb1_inst_d7  => hps_usb_data(7),
      hps_io_hps_io_usb1_inst_clk => hps_usb_clkout,
      hps_io_hps_io_usb1_inst_stp => hps_usb_stp,
      hps_io_hps_io_usb1_inst_dir => hps_usb_dir,
      hps_io_hps_io_usb1_inst_nxt => hps_usb_nxt,

      -- UART
      hps_io_hps_io_uart0_inst_rx    => hps_uart_rx,
      hps_io_hps_io_uart0_inst_tx    => hps_uart_tx,
      hps_io_hps_io_gpio_inst_gpio09 => hps_conv_usb_n,

      -- LTC connector
      hps_io_hps_io_gpio_inst_gpio40 => hps_ltc_gpio,
      hps_io_hps_io_spim1_inst_clk   => hps_spim_clk,
      hps_io_hps_io_spim1_inst_mosi  => hps_spim_mosi,
      hps_io_hps_io_spim1_inst_miso  => hps_spim_miso,
      hps_io_hps_io_spim1_inst_ss0   => hps_spim_ss,
      hps_io_hps_io_i2c1_inst_sda    => hps_i2c1_sdat,
      hps_io_hps_io_i2c1_inst_scl    => hps_i2c1_sclk,

      -- I2C for accelerometer
      hps_io_hps_io_gpio_inst_gpio61 => hps_gsensor_int,
      hps_io_hps_io_i2c0_inst_sda    => hps_i2c0_sdat,
      hps_io_hps_io_i2c0_inst_scl    => hps_i2c0_sclk,

      -- HPS user I/O
      hps_io_hps_io_gpio_inst_gpio53 => hps_led,
      hps_io_hps_io_gpio_inst_gpio54 => hps_key,

      -- DDR3
      memory_mem_a       => hps_ddr3_addr,
      memory_mem_ba      => hps_ddr3_ba,
      memory_mem_ck      => hps_ddr3_ck_p,
      memory_mem_ck_n    => hps_ddr3_ck_n,
      memory_mem_cke     => hps_ddr3_cke,
      memory_mem_cs_n    => hps_ddr3_cs_n,
      memory_mem_ras_n   => hps_ddr3_ras_n,
      memory_mem_cas_n   => hps_ddr3_cas_n,
      memory_mem_we_n    => hps_ddr3_we_n,
      memory_mem_reset_n => hps_ddr3_reset_n,
      memory_mem_dq      => hps_ddr3_dq,
      memory_mem_dqs     => hps_ddr3_dqs_p,
      memory_mem_dqs_n   => hps_ddr3_dqs_n,
      memory_mem_odt     => hps_ddr3_odt,
      memory_mem_dm      => hps_ddr3_dm,
      memory_oct_rzqin   => hps_ddr3_rzq,

      -- Fabric clock and reset
      clk_clk       		=> fpga_clk1_50,
      reset_reset_n 		=> rst_n


    );



end architecture de10nano_arch;
