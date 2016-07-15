	component cnst_rom is
		port (
			address : in  std_logic                    := 'X'; -- address
			clock   : in  std_logic                    := 'X'; -- clk
			q       : out std_logic_vector(7 downto 0)         -- dataout
		);
	end component cnst_rom;

	u0 : component cnst_rom
		port map (
			address => CONNECTED_TO_address, --  rom_input.address
			clock   => CONNECTED_TO_clock,   --           .clk
			q       => CONNECTED_TO_q        -- rom_output.dataout
		);

