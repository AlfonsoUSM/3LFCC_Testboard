`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.01.2023 11:04:28
// Design Name: 
// Module Name: 3LFCC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module LFCC
#(parameter freq_pwm = 10, Duty = 0.5, shift = 0)
(
    input logic CLK100MHZ,
    input logic CPU_RESETN,
    input logic [6:0] SW,
    input logic [3:0] dt,
    output logic [2:1]JD,
    output logic [2:1]JC
    );
    logic [6:0] N_on;
    assign N_on = SW;
    localparam integer N = (800/freq_pwm) - 2;
    localparam Bits = $clog2(N);
    localparam integer M = (((N+2)/2)*shift)/180;
    logic reset;
    assign reset = ~CPU_RESETN;
    logic clk_out11;
    logic clk_out22;
    logic clk_out33;
    logic clk_out44;
    logic clk_out55;
    logic clk_in1;
    assign clk_in1 = CLK100MHZ;
     clk_wiz_0 CLK
   (
    // Clock out ports
    .clk_out1(clk_out11),     // output clk_out1
    .clk_out2(clk_out22),     // output clk_out2
    .clk_out3(clk_out33),     // output clk_out3
    .clk_out4(clk_out44),     // output clk_out2
    .clk_out5(clk_out55),     // output clk_out3
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_in1));
    
    logic clk_pwm;
    assign clk_pwm = ((clk_out22 && clk_out33) ||(~clk_out22 && ~clk_out33)  );
    logic clk_pwm2;
    assign clk_pwm2 = ((clk_out44 && clk_out55) ||(~clk_out44 && ~clk_out55)  );

    logic sel;
    logic [Bits:0]D;
    logic [Bits:0]Q;
    logic [Bits:0]sum;
    logic pwm;
    assign sum = Q + 1'b1;
    assign sel = (Q<=N);
    always_comb begin
        case(sel)
            1'b1: D = sum;
            1'b0: D = 1'b0;
        endcase
    end
    assign pwm = (Q < N_on);
    always_ff @(posedge clk_pwm)begin
        if(reset)begin
                Q <= 'b0;
            end
        else begin
                Q <= D;
            end
        end
    logic pwm1;
    assign pwm1 = ~pwm;
    logic dt1;

    logic pwmout;
    logic pwmoutN;
    Dead_Time DT(
     .clk_pwm(clk_pwm),
     .reset(reset),
     .dt(dt),
     .pwm_input(pwm),
     .pwm(pwmout)
    );
        Dead_Time DT2(
     .clk_pwm(clk_pwm),
     .reset(reset),
     .dt(dt),
     .pwm_input(pwm1),
     .pwm(pwmoutN)
    );
    logic pwmout2;
    assign pwmout2 = ~pwmoutN;
    assign JD[1] = pwmout2;
    assign JD[2] = pwmout;
    assign JC[2] = clk_pwm;
    assign JC[1] = 'b0;
endmodule

module counter(
    input logic clk,
    input logic reset,
    input logic enable,
    output logic [6:0]Q
);
    logic [6:0]D;
    always_ff @(posedge clk) begin
        if(reset) begin 
            Q = 'b0;
        end
        else if((enable == 'b0))begin
            Q<='b0;
        end
        else begin 
            Q<=D;
        end
    end   
    always_comb begin
       D = Q+'b1;
    end
endmodule 

module Dead_Time(
    input logic clk_pwm,
    input logic reset,
    input logic [3:0]dt,
    input logic pwm_input,
    output logic pwm
    
    );
    logic comp;
    logic enable;
    logic [6:0]Q;
    counter counter(
    .clk(clk_pwm), 
    .reset(reset),
    .enable (enable),
    .Q(Q));
    
    always_comb begin
        if((pwm_input == 1'b1) && Q < dt)begin
            enable = 1'b1;
            comp = 1'b0;
        end
        else if((pwm_input == 1'b1) && Q >= dt)begin
            enable = 1'b1;
            comp = 1'b1;
        end
        else begin
            enable = 1'b0;
            comp = 1'b1; 
        end
    end

    assign pwm = comp && pwm_input;
endmodule