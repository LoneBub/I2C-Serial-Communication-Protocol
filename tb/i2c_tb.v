// TESTBENCH
module tb_i2c_master_slave;
reg reset,start_bit,rd_wr;
reg fpga_clk=0;
reg [6:0]address;
reg [7:0]slave_data,master_data;
wire [7:0]slave_d_out,master_data_out;

i2c_master_slave dut(reset,slave_data,master_data,start_bit,fpga_clk,rd_wr,address,slave_d_out,master_data_out);

always #10 fpga_clk = ~fpga_clk;
initial begin
reset = 0;
#4500 reset = 1;
end
initial begin
master_data = 8'b10110101;
slave_data = 8'b11011101;
address = 7'b1100011;
rd_wr = 0;
start_bit = 1;
#180000 start_bit = 0;

end
endmodule