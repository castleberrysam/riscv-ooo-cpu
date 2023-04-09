// age matrix
module agemat #(
  parameter WIDTH = 16,
  parameter OLDEST = 1
  )(
  input              clk,
  input              rst,

  input              insert_valid,
  input [WIDTH-1:0]  insert_sel,

  input [WIDTH-1:0]  req,
  output             grant_valid,
  output [WIDTH-1:0] grant);

  // Each bit in the matrix represents the relative age of the two entries
  // corresponding to the row and column index. On an allocation, we set the
  // corresponding row to 1 and the corresponding column to 0. E.g. assuming an
  // empty queue with WIDTH=5 and an allocation at index 1, this will be the
  // resulting state:
  //
  // 0 . . 0 .
  // . 0 . 0 .
  // . . 0 0 .
  // 1 1 1 0 1
  // . . . 0 0
  //
  // Then an allocation at index 3 will result in this state:
  //
  // 0 0 . 0 .
  // 1 0 1 1 1
  // . 0 0 0 .
  // 1 0 1 0 1
  // . 0 . 0 0
  //
  // When both entries request issue, we use this equation to find the oldest:
  //
  // grant[i] = req[i] & ~(req[j] & matrix[i][j]) for all j
  //
  // grant[1]=1  grant[3]=1
  // . . . . .   . . . . .
  // . . . . .   . 0 . 0 .
  // . . . . .   . . . . .
  // . 0 . 0 .   . . . . .
  // . . . . .   . . . . .
  //
  // As you can see this is only true for the oldest of all the requests.

  // row-major ([i][j] means row i column j)
  wire [WIDTH-1:0] matrix [0:WIDTH-1];

  // write side
  genvar row, col;
  generate
    assign matrix[0][0] = 1'b0;
    for(row = 1; row < WIDTH; row=row+1) begin
      wire [row-1:0] matrix_r, matrix_nxt;
      dff #(row) u_matrix_r (matrix_r, matrix_nxt, clk, insert_valid);
      for(col = 0; col < row; col=col+1) begin
        assign matrix_nxt[col] = ( matrix_r[col] |
                                   insert_sel[row] ) &
                                 ~insert_sel[col];
        assign matrix[row][col] = matrix_r[col];
        assign matrix[col][row] = ~matrix_r[col];
      end
      assign matrix[row][row] = 1'b0;
    end
  endgenerate

  // read side
  assign grant_valid = |req;

  genvar i, j;
  generate
    for(i = 0; i < WIDTH; i=i+1)
      if(OLDEST)
        assign grant[i] = req[i] & (~|(req & matrix[i]));
      else
        assign grant[i] = req[i] & (~|(req & ~matrix[i]));
  endgenerate

endmodule
