module tb_sha256_upd();

reg [31:0]input_data;
reg input_valid;
reg last_word = 1'b0;
reg [1:0] last_numbyte = 2'b0;
reg [6:0]blocks;
reg clk;
reg rst;
wire [255:0]hash_data;
wire output_valid;
integer fd,scan_file;

initial begin
clk = 1'b0;
input_valid = 1'b1;
blocks = 0;
fd = $fopen("E:/SHA-256/SHA-256-lite/string_hex.txt","r");  

rst = 1'b1;
#2;
rst = 1'b0;

end


sha256 UUT(input_data,
		   input_valid,
		   input_ready,
		   last_word,
		   last_numbyte,
		   clk,
		   rst,
		   output_valid,
		   hash_data);

always #10 clk = (~output_valid)^clk;

always @(posedge clk)
	begin
		if(input_ready==1'b1 && last_word == 1'b0)
		begin
			scan_file = $fscanf(fd, "%x\n", input_data); 
			blocks <= blocks + 1;
		end
	end


integer eof_int;
always @(posedge clk) eof_int = $feof(fd);//detected end of file

wire [31:0] eof_det;
assign	    eof_det = eof_int;

//last_word detected
always @(eof_det) 
	begin
		if(eof_det)	/*auto detected*/
			last_word = 1'b1;
	end
	

//last_numbyte detected	
wire 	cond3,cond2,cond1; 
assign  cond3 = ((|input_data[31:24]) === 1'bx) ? 1'b1 : 1'b0;
assign	cond2 = ((|input_data[23:16]) === 1'bx) ? 1'b1 : 1'b0;
assign	cond1 = ((|input_data[15:8 ]) === 1'bx) ? 1'b1 : 1'b0;
always @(eof_det)
	begin	
    if(eof_det) /*auto detected*/     
		last_numbyte = cond3 ? 2'd3 : 
					   cond2 ? 2'd2 :
					   cond1 ? 2'd1 : 2'd0;
					   
	end
	


endmodule
