module sha256(	input_data,
				input_valid,
				input_ready,
				last_word,
				last_numbyte,
				clk,
				rst,
				output_valid,
				hash_data);


input [31:0]input_data;
input input_valid;
input last_word;
input [1:0] last_numbyte;
input clk,rst;

output reg input_ready;
output wire [255:0]hash_data;
output wire output_valid;

wire [6:0]block_counter;
reg [4:0] length_counter;
reg [63:0]size;
reg [1:0]special;
reg [31:0]output_data;
reg D;
reg last_word_delayed;
reg [1:0]last_next;


always @(negedge rst)
begin
last_next = 2'b00;
input_ready <= 1'b1;
length_counter <= 5'd31;
special <= 2'd0;
size <= 64'hffffffffffffffe0;
//size   <= 64'hFFFFFFFFFFFFFFC0;
D <= 1'b1;
last_word_delayed <= 1'b0;
end


sha_engine Eng(output_data,clk,block_counter,rst,output_valid,hash_data,last_word,last_next);

always @(posedge clk)
begin

	if(input_valid == 1'b1 && input_ready == 1'b1)
	begin
		if(length_counter == 5'd14)
			input_ready <= 1'b0;

		length_counter = length_counter + 1;
	end
	
end

always @(posedge clk)
begin
	if(last_word == 1'b1)
		last_word_delayed <= 1'b1;
end

reg [1:0] last_numbyte_delayed = 1'b0;
always @(posedge clk)
	last_numbyte_delayed <= last_numbyte;

always @(posedge last_word_delayed)
begin
	if(length_counter<=13)
		special <= 2'b01;
	else if (length_counter == 14)
		special <= (|last_numbyte_delayed) ? 2'b01 : 2'b11;
	else // > 14
		special <= 2'b11;
end

	
always @(posedge clk)
begin
	case(special)
		2'b00 : begin
			if (last_word)
				begin
				output_data <= (last_numbyte == 1) ? {input_data[7:0 ],1'b1,23'b0} : 
				               (last_numbyte == 2) ? {input_data[15:0],1'b1,15'b0} : 
							   (last_numbyte == 3) ? {input_data[23:0],1'b1, 7'b0} : input_data;
					
				D <= ~(|last_numbyte);
				end
			else
				output_data <= input_data;
			last_next <= 2'b00;
			end
		2'b01 : begin
			last_next <= 2'b01;

			if(length_counter<15)
				begin
					if(length_counter == 1 && size == 512)
						output_data <= {1'b1,{31{1'b0}}};
					else 
						begin
						D <= 1'b0;
						output_data <= {D,{31{1'b0}}};
						end
				end
			else if(length_counter == 15)
				begin
					output_data <= size[63:32];
					length_counter <= length_counter + 1;
				end
			else
				output_data <= size[31:0];
			end
		2'b11 : begin
				last_next <= 2'b10;
				D <= 1'b0;
				output_data <= {D,{31{1'b0}}};

			end
	endcase
end

always @(posedge clk)
begin
	if(block_counter == 64)
	begin
		length_counter <= 5'd31;
		input_ready <= 1'b1;
	end
	if(block_counter == 65)
	begin
		if(special == 3)
			special <= 2'b01;
		else
			special <= 2'd0;
	end
end

always @(posedge clk)
begin
	if(input_ready == 1 && special == 0)
		if (last_word)
			size <= (last_numbyte == 1) ? (size + 8)  : 
					(last_numbyte == 2) ? (size + 16) : 
					(last_numbyte == 3) ? (size + 24) : (size + 32);
		else
			size <= size + 32;
end

always @(posedge last_word)
begin
	if(length_counter == 15)
		if (last_word)
			size <= (last_numbyte == 1) ? (size + 8)  : 
					(last_numbyte == 2) ? (size + 16) : 
					(last_numbyte == 3) ? (size + 24) : (size + 32);
		else
			size <= size + 32;
end
endmodule