
module hex8 (
    input wire clk,
    input wire reset,
    output wire [7:0] a_value,
    output wire [7:0] b_value,
    output wire [7:0] pc_value
);

reg [7:0] a_reg;
reg [7:0] b_reg;
reg [3:0] o_reg_low;
reg [3:0] o_reg_high;
reg [7:0] r_reg;
reg [7:0] pc;
reg [3:0] i_reg;

assign a_value = a_reg;
assign b_value = b_reg;
assign pc_value = pc;

reg [7:0] memory [0:255];
reg [2:0] pipeline;
reg [1:0] phi;

wire pfix;
wire load_i_reg;
wire au_sub;
wire comp_select;
wire mem_write;
wire r_mux_sel;
wire a_reg_en;
wire b_reg_en;
wire pc_en;
wire fetch;
wire inc;
wire exec;

wire [7:0] o_reg;

wire [1:0] a_mux_sel;
wire [1:0] b_mux_sel;

wire [7:0] result;
reg [7:0] a_result;
reg [7:0] b_result;
wire [7:0] au_result;
wire comp_zero;
wire comp_neg;
wire condition;

wire [15:0] operation;

localparam LDAM = 0; // Asel = 10, bBsel = 10, A_reg_en = 1
localparam LDBM = 1; // Asel = 10, Bsel = 10, B_reg_en = 1
localparam STAM = 2; // Asel = 10, Bsel = 10, mem_write = 1
localparam LDAC = 3; // Asel = 10, Bsel = 10, Rsel = 1, A_reg_en = 1
localparam LDBC = 4; // Asel = 10, Bsel = 10, Rsel = 1, B_reg_en = 1
localparam LDAP = 5; // Asel = 01, Bsel = 01, Rsel = 1, A_reg_en = 1
localparam LDAI = 6; // Bsel = 01, A_reg_en = 1
localparam LDBI = 7; // Asel = 10, B_reg_en = 1
localparam STAI = 8; // Asel = 10, mem_write = 1
localparam BR   = 9; // Asel = 01, Bsel = 01, Rsel = 1, pc_en = 1
localparam BRZ  = 10; // Asel = 01, Bsel = 01, Rsel = 1, pc_en = condition
localparam BRN  = 11; // comp_sel = 1, Asel = 01, Bsel = 01, Rsel = 1, pc_en = condition
localparam BRB  = 12; // Asel = 11, Rsel = 1, pc_en = 1
localparam ADD  = 13; // Rsel = 1, A_reg_en = 1
localparam SUB  = 14; // Rsel = 1, A_reg_en = 1, subtract = 1
localparam PFIX = 15; // pfix = 1

// fetch: Asel = 01, Bsel = 10, load_i_ireg = 1
// inc:   Asel = 01, Bsel = 10, Rsel = 1, pc_en = 1

assign fetch = pipeline[0];
assign inc = pipeline[1];
assign exec = pipeline[2];

assign operation = 16'b0 | ({15'b0, exec} << i_reg);
assign o_reg = {o_reg_high, o_reg_low};

assign pfix = operation[PFIX];
assign load_i_reg = fetch;
assign au_sub = operation[SUB];
assign comp_select = operation[BRN];
assign mem_write = operation[STAM] | operation[STAI];
assign r_mux_sel = |operation[5:3] | |operation[14:9] | inc;
assign a_reg_en = operation[LDAM] | operation[LDAI] | operation[LDAC] | operation[LDAP] | operation[ADD] | operation[SUB];
assign b_reg_en = operation[LDBM] | operation[LDBI] | operation[LDBC];
assign pc_en = operation[BR] | operation[BRB] | inc | (operation[BRZ] & condition) | (operation[BRN] & condition);

assign a_mux_sel[0] = operation[LDAP] | operation[BR] | operation[BRZ] | operation[BRN] | operation[BRB] | fetch | inc;
assign a_mux_sel[1] = |operation[4:0] | operation[LDBI] | operation[STAI] | operation[BRB];
assign b_mux_sel[0] = operation[LDAP] | operation[LDAI] | operation[BR] | operation[BRZ] | operation[BRN];
assign b_mux_sel[1] = fetch | inc | |operation[4:0];

assign comp_zero = ~(|a_result);
assign comp_neg = a_result[7];

assign condition = (comp_select) ? comp_neg : comp_zero;

always @ (*) begin
    case (a_mux_sel)
        2'b00: a_result = a_reg;
        2'b01: a_result = pc;
        2'b10: a_result = o_reg;
        2'b11: a_result = 8'b0;
    endcase

    case (b_mux_sel)
        2'b00: b_result = b_reg;
        2'b01: b_result = o_reg;
        2'b10: b_result = 8'b0;
        2'b11: b_result = 8'b0;
    endcase 
end

assign au_result = (au_sub) ?
                   a_result - b_result :
                   a_result + b_result + {7'b0, inc};

assign result = (r_mux_sel) ? au_result : memory[au_result];

always @ (posedge clk) begin
    case (phi)
        2'b01: phi <= 2'b10;
        2'b10: phi <= 2'b01;
        default: phi <= phi;
    endcase
    if (phi == 2'b10) begin
        case (pipeline)
            3'b001: pipeline <= 3'b010;
            3'b010: pipeline <= 3'b100;
            3'b100: pipeline <= 3'b001;
            default: pipeline <= pipeline;
        endcase
    end
    if (phi[1] && a_reg_en) a_reg <= r_reg;
    if (phi[1] && b_reg_en) b_reg <= r_reg;
    if (phi[1] && pc_en) pc <= r_reg;
    if (phi[1] && load_i_reg) o_reg_low <= r_reg[3:0];
    if (phi[1] && load_i_reg) i_reg <= r_reg[7:4];
    if (phi[1] && exec) o_reg_high <= pfix ? o_reg[3:0] : 4'b0;
    if (phi[0]) r_reg <= result;
    if (mem_write) memory[au_result] <= a_result;

    if (reset) begin
        phi <= 2'b01;
        pipeline <= 3'b001;
        a_reg <= 8'b0;
        b_reg <= 8'b0;
        o_reg_low <= 4'b0;
        o_reg_high <= 4'b0;
        i_reg <= 4'b0;
        pc <= 8'b0;
        r_reg <= 8'b0;
    end
end

initial $readmemh("fact3.hex", memory);

endmodule
