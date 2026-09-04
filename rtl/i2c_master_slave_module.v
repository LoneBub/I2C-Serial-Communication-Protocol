///////////////////////////////////////// I2C MASTER MODULE ////////////////////////////////
// PISO ADDRESS 
module PISO_address(serial_out,load_addr,shift_addr,sclk,rd_wr,address_in);
input load_addr,shift_addr,sclk,rd_wr;
input [6:0]address_in;
output serial_out;
reg [7:0]addr;

always @(negedge sclk)
begin
//if(!reset)
//data <= 8'b0000_0000;
if(load_addr)
addr <= {address_in,rd_wr};
else if(shift_addr)
addr <= {addr[6:0],1'b0};
else
addr <= addr;
end
assign serial_out = addr[7];
endmodule

// PISO DATA
module PISO_data(serial_out,load_data,shift_data,sclk,data_in);
input load_data,shift_data,sclk;
input [7:0]data_in;
output serial_out;
reg [7:0]data;

always @(negedge sclk)
begin
//if(!reset)
//data <= 8'b0000_0000;
if(load_data)
data <= data_in;
else if(shift_data)
data <= {data[6:0],1'b0};
else
data <= data;
end
assign serial_out = data[7];
endmodule

//SIPO DATA
module SIPO_data(sclk,serial_in,data_out,shift_data);
input serial_in,shift_data,sclk;
output [7:0]data_out;
reg [7:0]register;

always @(posedge sclk)
//if(!reset)
//register <= 8'bxxxx_xxxx;
if (shift_data == 1)
register <= {register[6:0],serial_in};
else
register <= register;

assign data_out = register;
endmodule

// 4*1 MUX
module mux4(sel,data,address,ack,mux_out);
input [1:0]sel;
input data,address,ack;
output reg mux_out;
always @(sel,data,address)
case(sel)
2'b00 : mux_out = 1'b0;
2'b01 : mux_out = address;
2'b10 : mux_out = data;
2'b11 : mux_out = ack;
endcase
endmodule

//1*2 DEMUX
module demux_2(demux_in,ack,slave_data,demux_sel);
output reg ack,slave_data;
input demux_in,demux_sel;

always @(demux_sel,demux_in)
case(demux_sel)
1'b0 : begin ack = demux_in; slave_data = 1'b0; end
1'b1 : begin ack = 1'b0; slave_data = demux_in; end
endcase
endmodule

//TRISTATE LOGIC
module tristate_buff(SDA_out,tri_en,SDA_in,SDA);
input SDA_out,tri_en;
inout tri1 SDA;
output SDA_in;
bufif0 b1(SDA,SDA_out,tri_en);
buf b2(SDA_in,SDA);
endmodule

// 2*1 MUX
module mux2(ack_sel,ack_out);
input ack_sel;
output reg ack_out;
parameter ack = 1'b0 , nack = 1'b1;
always @(ack_sel)
case(ack_sel)
1'b0 : ack_out = ack;
1'b1 : ack_out = nack;
endcase
endmodule 


/////////// I2C MASTER FSM ///////////
module i2c_master_fsm(reset,start_bit,rd_wr,ack_from_slave,sclk,load_addr,shift_addr,load_data,shift_data,mux_sel,tri_en,scl_en,shift_d_slave,ack_sel,demux_sel);
input reset,start_bit,rd_wr,ack_from_slave,sclk;
output reg load_addr,shift_addr,load_data,shift_data,ack_sel;
output reg tri_en,scl_en,shift_d_slave,demux_sel;
output reg [1:0]mux_sel;
reg [3:0] state,next_state;
integer count_s = 1;
integer count_r = 1;
reg count_rx_start = 0;
reg count_send_start = 0;
parameter idle = 4'b0000, start = 4'b0001, transmit_scl = 4'b0010, address = 4'b0011, ack_ad = 4'b0100, 
receive_data = 4'b0101,send_data = 4'b0110, ack_sd = 4'b0111, ack_rd = 4'b1000, stop = 4'b1001;

always @(reset,start_bit,rd_wr,ack_from_slave,sclk,mux_sel,count_s,count_r) begin
case(state)
idle: next_state = start_bit ? start : idle;
start:  next_state = transmit_scl;
transmit_scl: next_state = address;
address: begin
count_send_start = (count_s == 8)?0:1;
next_state = (count_s == 8)?ack_ad:address; end
ack_ad: begin
next_state = ((ack_from_slave == 0) ?(rd_wr?receive_data:send_data) : idle); end
receive_data : begin
count_rx_start = (count_r == 8)?0:1;
next_state = (count_r == 8)?ack_sd:receive_data;
end
send_data : begin
count_send_start = (count_s == 8)?0:1;
next_state = (count_s == 8)?ack_rd:send_data;
end
ack_rd: next_state = (ack_from_slave == 0)?stop:send_data;
ack_sd: next_state = stop;
stop: next_state = idle;
default: next_state = idle;
endcase
end

always @(negedge sclk or negedge reset)
if(!reset)
state <= idle;
else
state <= next_state;

always @(negedge sclk)
if(count_rx_start)
count_r <= count_r + 1;
else
count_r <= 1;

always @(negedge sclk)
if(count_send_start)
count_s <= count_s + 1;
else
count_s <= 1;

always @(state)
begin
if(state == idle) begin
tri_en    = 1;     load_addr  = 0;  shift_addr    = 0;  
load_data = 0;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'bxx; demux_sel  = 0;  ack_sel       = 0;  scl_en = 0;
end
else if(state == start) begin
tri_en    = 0;     load_addr  = 1;  shift_addr    = 0;  
load_data = 0;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'b00; demux_sel  = 0;  ack_sel       = 0;  scl_en = 0;
end
else if(state == transmit_scl) begin
tri_en    = 0;     load_addr  = 0;  shift_addr    = 0;  
load_data = 0;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'b00; demux_sel  = 0;  ack_sel       = 0;  scl_en = 1;
end
else if(state == address) begin
tri_en    = 0;     load_addr  = 0;  shift_addr    = 1;  
load_data = 0;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'b01; demux_sel  = 0;  ack_sel       = 0;  scl_en = 1;
end
else if(state == ack_ad) begin
tri_en    = 1;     load_addr  = 0;  shift_addr    = 0;  
load_data = 1;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'b00; demux_sel  = 0;  ack_sel       = 0;  scl_en = 1;
end
else if(state == send_data) begin
tri_en    = 0;     load_addr  = 0;  shift_addr    = 0;  
load_data = 0;     shift_data = 1;  shift_d_slave = 0;
mux_sel   = 2'b10; demux_sel  = 0;  ack_sel       = 0;  scl_en = 1;
end
else if(state == receive_data) begin
tri_en    = 1;     load_addr  = 0;  shift_addr    = 0;  
load_data = 0;     shift_data = 0;  shift_d_slave = 1;
mux_sel   = 2'b00; demux_sel  = 1;  ack_sel       = 0;  scl_en = 1;
end
else if(state == ack_rd) begin
tri_en    = 1;     load_addr  = 0;  shift_addr    = 0;  
load_data = 0;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'b11; demux_sel  = 0;  ack_sel       = 0;  scl_en = 1;
end
else if(state == ack_sd) begin
tri_en    = 0;     load_addr  = 0;  shift_addr    = 0;  
load_data = 0;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'b11; demux_sel  = 0;  ack_sel       = 1;  scl_en = 1;
end
else if(state == stop) begin
tri_en    = 1;     load_addr  = 0;  shift_addr    = 0;  
load_data = 0;     shift_data = 0;  shift_d_slave = 0;
mux_sel   = 2'b11; demux_sel  = 0;  ack_sel       = 0;  scl_en = 0;
end
end
endmodule 

// TOP MODULE I2C MASTER
module i2c_master(reset,start_bit,sclk,scl,rd_wr,address,data,sda,slave_data);
input reset,start_bit,rd_wr;
output tri1 scl;
inout tri1 sda;
input [6:0]address;
input [7:0]data;
output [7:0]slave_data;
wire load_addr,shift_addr,piso_addr_out,load_data,shift_data,fsm_ack_sel,ack_mux_out,piso_data_out,tri_en,demux_sel,ack_from_slave,shift_d_slave,scl_en,demux_data_in,SDA_in,SDA_out;
wire [1:0]fsm_mux_sel;
input sclk;

PISO_address piso_addr(piso_addr_out,load_addr,shift_addr,sclk,rd_wr,address);
PISO_data piso_d(piso_data_out,load_data,shift_data,sclk,data);
SIPO_data sipo_d(sclk,demux_data_in,slave_data,shift_d_slave);
mux4 mux41(fsm_mux_sel,piso_data_out,piso_addr_out,ack_mux_out,SDA_out);
demux_2 dem2(SDA_in,ack_from_slave,demux_data_in,demux_sel);
tristate_buff tbuff(SDA_out,tri_en,SDA_in,sda);
mux2 m2(fsm_ack_sel,ack_mux_out);
i2c_master_fsm i2c_master(reset,start_bit,rd_wr,ack_from_slave,sclk,load_addr,shift_addr,load_data,shift_data,fsm_mux_sel,tri_en,scl_en,shift_d_slave,fsm_ack_sel,demux_sel);
bufif1 buf1(scl,sclk,scl_en);

endmodule

//Testbench
module tb_i2c_master;
reg reset,start_bit,sclk,rd_wr;
reg [6:0]address;
reg [7:0]data;
wire sda,scl;
wire [7:0]slave_data;
i2c_master dut(reset,start_bit,sclk,scl,rd_wr,address,data,sda,slave_data);

always #5 sclk = ~sclk;

initial begin
sclk=0;
#2 reset = 0;
#1 reset = 1;
#3 start_bit = 1;
#1 address = 7'b1001001; rd_wr = 0;
#100 start_bit = 0;

// force sda = 1'b0 from 110ns to 120ns and ack_frm_slave = 1'b0 frm 200ns to 210ns
end

initial
data = 8'b10101010;
endmodule 

/////////////////////////////////////////// I2C SLAVE MODULE ////////////////////////////////////////////////////////

// START-STOP-DETECTOR
module tff(in,out,clk,reset); // tflip-flop
input in,clk,reset;
output reg out;

always @(posedge clk or negedge reset) begin
if(!reset)
out <= 1;
else if(in)
out <= !out;
else
out <= out;
end
endmodule 

module reg1(in,out,clk,load,reset);  // dff1 on posedge
input in,load,clk,reset;
output reg out;

always @(posedge clk or negedge reset) begin
if(!reset)
out <= 0;
else if(load)
out <= in;
end
endmodule

module reg2(in,out,clk,load,reset); // dff2 on negedge
input in,load,clk,reset;
output reg out;

always @(negedge clk or negedge reset) begin
if(!reset)
out <= 0;
else if(load)
out <= in;
end
endmodule

//start-stop-top
module start_stop_detector(start_stop_out,reset,sda_in,slave_scl);
output start_stop_out;
input reset,sda_in,slave_scl;
wire t,s0,s1;

tff tff1(slave_scl,t,sda_in,reset);
reg1 dff1(t,s1,sda_in,slave_scl,reset);
reg2 dff2(t,s0,sda_in,slave_scl,reset);
assign start_stop_out = ~(s0^s1);

endmodule

//SIPO_ADDRESS
module SIPO_addr_slave(slave_scl,sda_in,slave_address,slave_rd_wr,shift_addr);
input sda_in,shift_addr,slave_scl;
output [6:0]slave_address;
output slave_rd_wr;
reg [7:0]register;

always @(posedge slave_scl)
if (shift_addr == 1)
register <= {register[6:0],sda_in};
else
register <= register;

assign {slave_address,slave_rd_wr} = register;
endmodule

//SIPO_DATA
module SIPO_data_slave(slave_scl,sda_in,master_data_out,shift_data);
input sda_in,shift_data,slave_scl;
output [7:0]master_data_out;
reg [7:0]register;

always @(posedge slave_scl)
if (shift_data == 1)
register <= {register[6:0],sda_in};
else
register <= register;

assign master_data_out = register;
endmodule

// PISO DATA
module PISO_data_slave(data_slave_out,load_data,shift_data,slave_scl,data_in);
input load_data,shift_data,slave_scl;
input [7:0]data_in;
output data_slave_out;
reg [7:0]data;

always @(negedge slave_scl)
begin
//if(!reset)
//data <= 8'b0000_0000;
if(load_data)
data <= data_in;
else if(shift_data)
data <= {data[6:0],1'b0};
else
data <= data;
end
assign data_slave_out = data[7];
endmodule 

//TRISTATE LOGIC
module tristate_buff_slave(sda_out,tri_en,sda_in,sda);
input sda_out,tri_en;
inout tri1 sda;
output sda_in;
bufif0 b1(sda,sda_out,tri_en);
buf b2(sda_in,sda);
endmodule

// 2*1 MUX ACK
module mux2_slave_ack(ack_sel,ack_out);
input ack_sel;
output reg ack_out;
parameter ack = 1'b0 , nack = 1'b1;
always @(ack_sel)
case(ack_sel)
1'b0 : ack_out = nack;
1'b1 : ack_out = ack;
endcase
endmodule 

// 2*1 MUX
module mux2_slave(data_slave,mux_sel,sda_out,ack_from_slave);
input data_slave,mux_sel,ack_from_slave;
output reg sda_out;
always @(*)
case(mux_sel)
1'b0 : sda_out = ack_from_slave;
1'b1 : sda_out = data_slave;
endcase
endmodule 

/////////// I2C SLAVE FSM ///////////
module i2c_slave_fsm(reset,sda_in,slave_scl,start_stop_detect,slave_rd_wr,address_rx,shift_addr,shift_data_master,mux_sel,tri_en,shift_d_slave,load_data,ack_sel);
input reset,sda_in,slave_scl,start_stop_detect,slave_rd_wr;
input [6:0]address_rx;
output reg shift_addr,shift_data_master,shift_d_slave,load_data;
output reg mux_sel,tri_en,ack_sel;
reg [3:0] state,next_state;
integer count = 1;
reg count_start = 0;

parameter slave_device_address = 7'b1100011;
parameter detect_start = 4'b0000, start = 4'b0001, address_detect = 4'b0010, read_write = 4'b0011, receive_data = 4'b0100, 
ack_rd = 4'b0101,send_data = 4'b0110, ack_sd = 4'b0111, stop = 4'b1000;

always @(reset,start_stop_detect,slave_rd_wr,ack_sel,slave_scl,mux_sel,count,sda_in) begin
case(state)
detect_start: next_state = start_stop_detect ? detect_start:start;
start:  next_state = address_detect;
address_detect: begin
count_start = (count == 8)?0:1;
next_state = (count == 8)?read_write:address_detect; end
read_write: begin
next_state = ((address_rx == slave_device_address) ?(slave_rd_wr?send_data:receive_data) : detect_start); end
receive_data : begin
count_start = (count == 8)?0:1;
next_state = (count == 8)?ack_sd:receive_data;
end
send_data : begin
count_start = (count == 8)?0:1;
next_state = (count == 8)?ack_rd:send_data;
end
ack_rd: next_state = (sda_in == 0)?stop:detect_start;
ack_sd: next_state = stop;
stop: next_state = start_stop_detect ? detect_start:stop;
default: next_state = detect_start;
endcase
end

always @(negedge slave_scl or negedge reset)  // DOUBT negedge or posedge
if(!reset)
state <= detect_start;
else
state <= next_state;

always @(negedge slave_scl)
if(count_start)
count <= count + 1;
else
count <= 1;

always @(state,slave_rd_wr)
begin
if(state == detect_start) begin
tri_en    = 1;    shift_addr    = 0;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 0;    mux_sel   = 0;     
end
else if(state == start) begin
tri_en    = 1;    shift_addr    = 0;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 0;    mux_sel   = 0; 
end
else if(state == address_detect) begin
tri_en    = 1;    shift_addr    = 1;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 0;    mux_sel   = 0; 
end
else if(state == read_write) begin
tri_en    = 0;    shift_addr    = 0;  shift_data_master = 0;
load_data = slave_rd_wr?1:0;    shift_d_slave = 0;
ack_sel   = (address_rx == slave_device_address);    mux_sel   = 0; 
end
else if(state == send_data) begin
tri_en    = 0;    shift_addr    = 0;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 1;
ack_sel   = 0;    mux_sel   = 1; 
end
else if(state == receive_data) begin
tri_en    = 1;    shift_addr    = 0;  shift_data_master = 1;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 0;    mux_sel   = 0; 
end
else if(state == ack_sd) begin
tri_en    = 0;    shift_addr    = 0;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 0;    mux_sel   = 0; 
end
else if(state == ack_rd) begin
tri_en    = 1;    shift_addr    = 0;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 1;    mux_sel   = 0; 
end
else if(state == stop) begin
tri_en    = 1;    shift_addr    = 0;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 0;    mux_sel   = 0; 
end
else begin
tri_en    = 1;    shift_addr    = 0;  shift_data_master = 0;
load_data = 0;    shift_d_slave = 0;
ack_sel   = 0;    mux_sel   = 0; 
end
end
endmodule 

// TOP MODULE I2C SLAVE
module i2c_slave(reset,sda,slave_scl,master_data_out,slave_data_in);
input reset;
input [7:0]slave_data_in;
output [7:0]master_data_out;
input slave_scl;
inout sda;

wire sda_in,tri_en,sda_out,start_stop_detect,shift_addr,slave_rd_wr,shift_data,shift_d_slave,load_data,data_slave_out,ack_sel,ack_out,mux_sel;
wire [6:0]slave_address;


start_stop_detector start_stop(start_stop_detect,reset,sda_in,slave_scl);
SIPO_addr_slave addr_slave(slave_scl,sda_in,slave_address,slave_rd_wr,shift_addr);
SIPO_data_slave data_slave(slave_scl,sda_in,master_data_out,shift_data);
PISO_data_slave piso_data(data_slave_out,load_data,shift_d_slave,slave_scl,slave_data_in);
tristate_buff_slave trib(sda_out,tri_en,sda_in,sda);
i2c_slave_fsm slave_fsm(reset,sda_in,slave_scl,start_stop_detect,slave_rd_wr,slave_address,shift_addr,shift_data,mux_sel,tri_en,shift_d_slave,load_data,ack_sel);
mux2_slave_ack slave_ack(ack_sel,ack_out);
mux2_slave muxslave(data_slave_out,mux_sel,sda_out,ack_out);

endmodule
////////////////////////////////////////////////////// SCL GENERATOR ///////////////////////////////////////////////////////////
module scl_generator(fpga_clk,scl_clk);
input fpga_clk;
output scl_clk;
integer count=0;

always @(posedge fpga_clk)
if(count<500)
count <= count + 1;
else
count = 1;
assign scl_clk = (count < 251) ? 1:0;
endmodule

///////////////////////////////////////////////// I2C MASTER-SLAVE TOP MAIN MODULE //////////////////////////////////////////////////
module i2c_master_slave(reset,slave_data,master_data,start_bit,fpga_clk,rd_wr,address,slave_d_out,master_data_out);
input reset,start_bit,fpga_clk,rd_wr;
input [6:0]address;
input [7:0]slave_data,master_data;
output [7:0]slave_d_out,master_data_out;
wire sda,scl,scl_clk;

scl_generator sclgen(fpga_clk,scl_clk);
i2c_master master(reset,start_bit,scl_clk,scl,rd_wr,address,master_data,sda,slave_d_out);
i2c_slave slave(reset,sda,scl,master_data_out,slave_data);

endmodule 

