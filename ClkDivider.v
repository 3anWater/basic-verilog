//--------------------------------------------------------------------------------
// ClkDivider.v
// Konstantin Pavlov, pavlovconst@gmail.com
//--------------------------------------------------------------------------------

// INFO --------------------------------------------------------------------------------
//  �������� ��������� ��������� �������.
//  ��������� �������� ����������� ��������� ����� ���������� � �������.

module ClkDivider(clk,nrst,out);

input wire clk;
input wire nrst;
output reg [(WIDTH-1):0] out = 0;

parameter WIDTH = 32;

always @ (posedge clk) begin
	if (~nrst) begin
		out <= 0;
	end
	else begin
		out <= out + 1;
	end
end

endmodule