
`timescale 1ns/1ps 
`define ASYNC 1
  
 module tb_pwm_ctr ;

    


 
	



    reg                pclk      ;
    reg                preset_n  ;
    wire [31:0]        paddr     = 0;
    reg  [15:0]        pwdata    ;
    wire               pwrite    = 1;
    wire               psel      = 1;
    wire               penable   = 1;
    wire [1:0]         pstrb     = 3;
    wire [15:0]        prdata    ;
    wire               pready    ;
    wire               pslverr   ;

    reg                core_clk  ;
    reg                core_rst_n;
    wire               pwm_o     ;


	initial begin 
		pclk = 0;
		preset_n  = 0; 
		#100 
		preset_n = 1;
	end
	
	always 
	begin
		#8 
		pclk = 1;
		#8 
		pclk = 0;
	end 

	initial begin 
		core_clk = 0;
		core_rst_n  = 0; 
		#100 
		core_rst_n = 1;
	end
	
    
    // 2^16*4 = 262.144MhZ
	always 
	begin
		#1.907 
		core_clk = 1;
		#1.907 
		core_clk = 0;
	end 



    reg [15:0] data;


    
    always@(posedge pclk or negedge preset_n)  
    if (!preset_n)   pwdata = 0;
    else             pwdata = pwdata + 1;







    pwm_ctr pwm_ctr
	(
		 
		pclk        ,
		preset_n         ,
		paddr       ,
		pwdata      ,
		pwrite      ,
		psel        ,
		penable     ,
		pstrb       ,
		prdata      ,
		pready      ,
		pslverr     ,
        
        core_clk,
        core_rst_n,
        
        pwm_o



	);
    
    
    
    
    
endmodule

