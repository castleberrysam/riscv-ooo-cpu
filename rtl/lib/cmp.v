module cmp #(
  parameter WIDTH = 32,
  parameter GROUP = 4,
  parameter SIGNED = 0
  )(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output            eq,
  output            lt);

  genvar i;
  generate
    if(GROUP < WIDTH) begin
      wire [WIDTH/GROUP-1:0] group_eq, group_lt;
      for(i = 0; i < WIDTH/GROUP; i=i+1) begin
        cmp #(GROUP,GROUP,0) u_group (
          .a(a[i*GROUP+:GROUP]),
          .b(b[i*GROUP+:GROUP]),
          .eq(group_eq[i]),
          .lt(group_lt[i]));
      end

      wire [WIDTH/GROUP-1:0] group_all_eq;
      for(i = 0; i < WIDTH/GROUP; i=i+1) begin
        assign group_all_eq[i] = (&group_eq[WIDTH/GROUP-1:i]);
      end

      wire lt_base;
      assign eq = group_all_eq[0];
      assign lt_base = group_lt[WIDTH/GROUP-1] |
                       (|( group_lt[WIDTH/GROUP-2:0] &
                           group_all_eq[WIDTH/GROUP-1:1] ));
      if(SIGNED)
        assign lt = lt_base ^ a[WIDTH-1] ^ b[WIDTH-1];
      else
        assign lt = lt_base;
    end else begin
      assign eq = (a == b);
      assign lt = (a < b);
    end
  endgenerate

endmodule
