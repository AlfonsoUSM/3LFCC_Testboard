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
#(parameter freq_pwm = 10)
(
    input logic CLK100MHZ,
    input logic CPU_RESETN,
    input logic [6:0] SW,//duty cycle(DC = SW/80)
    input logic [3:0] dt,//dt in pwm clock cycles
    output logic [2:1]JD,//output port 1
    output logic [2:1]JC//output port 2
    );
    logic [6:0] N_on;
    logic [6:0] SW1;    
    
    
    localparam integer N = (800/freq_pwm) - 2;//contador de periodo de la PWM con reloj base de 800 Mhz
    localparam Bits = $clog2(N);//Bits para el contador
    logic reset;
    assign reset = ~CPU_RESETN;//reset
    
    always_comb begin//Condición para que el duty cycle no sea menor a 1 ni mayor al periodo
        if((SW == 1'b0)|| (SW > N))begin
            SW1 = N;
        end
        
        else begin
            SW1 = SW;
        end
            
    end
    assign N_on = SW1;
    
    logic clk_out11;//Creacion de relojes
    logic clk_out22;
    logic clk_out33;
    logic clk_in1;
    assign clk_in1 = CLK100MHZ;
     clk_wiz_0 CLK
   (
    // Clock out ports
    .clk_out1(clk_out11),     // output clk_out1
    .clk_out2(clk_out22),     // output clk_out2
    .clk_out3(clk_out33),     // output clk_out3
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_in1));
    
    logic clk_pwm;
    assign clk_pwm = ((clk_out22 && clk_out33) ||(~clk_out22 && ~clk_out33)  );//clock 800Mhz 
   
    logic sel;//Generación PWM1
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
    
    logic sel2;//Generación PWM2 90 grados de desfase
    logic [Bits:0]D2;
    logic [Bits:0]Q2;
    logic [Bits:0]sum2;
    logic pwm2;
    assign sum2 = Q2 + 1'b1;
    assign sel2 = (Q2<=N);
    always_comb begin
        case(sel2)
            1'b1: D2 = sum2;
            1'b0: D2 = 1'b0;
        endcase
    end
    assign pwm2 = (Q2 < N_on);
    always_ff @(posedge clk_pwm)begin
        if(reset)begin
                Q2 <= (N/2)+ 1'b1;//Desfase en 90 grados
            end
        else begin
                Q2 <= D2;
            end
        end    
        
        
        
    logic pwmN;
    logic pwmN2;
    assign pwmN = ~pwm;
    assign pwmN2 = ~pwm2;
   
    logic [3:0]dt1;

    logic pwmout;
    logic pwmoutN;
    logic pwmout2;
    logic pwmoutN2;
    
    always_comb begin//evita que los tiempos muertos sean menores a 1 o mayores al periodo
        if((dt<'b1)||(dt>N)) begin
            dt1 = 4'd2;
        end
        else begin
            dt1 = dt;
        end
    end
    
    //Generacion de las señales pwm de salida
    Dead_Time DT(
     .clk_pwm(clk_pwm),
     .reset(reset),
     .dt(dt1),
     .pwm_input(pwm),
     .pwm(pwmout)
    );
        Dead_Time DT2(
     .clk_pwm(clk_pwm),
     .reset(reset),
     .dt(dt1),
     .pwm_input(pwmN),
     .pwm(pwmoutN)
    );
    
    Dead_Time DT3(
     .clk_pwm(clk_pwm),
     .reset(reset),
     .dt(dt1),
     .pwm_input(pwm2),
     .pwm(pwmout2)
    );
       Dead_Time DT4(
     .clk_pwm(clk_pwm),
     .reset(reset),
     .dt(dt1),
     .pwm_input(pwmN2),
     .pwm(pwmoutN2)
    );
    //Asignación de pines de salida 
    assign JD[1] = ~pwmoutN;
    assign JD[2] = pwmout;
    assign JC[1] = ~pwmoutN2;
    assign JC[2] = pwmout2;
endmodule

//Contador con enable
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

//generacion de tiempo muerto (agrega el tiempo muerto en el canto de subida)
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