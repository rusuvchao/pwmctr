
  
 module   pwm_config
	(
		input          pclk,    //  
        input          core_clk,  // Assume CORE clock can only be faster or as fast as the APB clock
		input          rsn,     

        //pclk domain
        input       [15:0]  MEM0,
        input       [15:0]  MEM1,

        
        //core clk domain    
		output       [15:0]  data,      
		output       [ 3:0]  PWM_PRD, //0=0.5ms 1=0.50ms  2=0.75ms  3=1.00ms  4=1.25ms   5=1.50ms   6=1.75ms   7=2.00ms
        output       [ 2:0]  PWM_RES, //resolution: 0=12bit(default), 1=13bits,2=14bit, 3=15bit, 4=16bit;
        output               PWM_POL // polarity, 0=idle_level_low 1=idle_level_high
	);
    
    
    // pclk domain 
    reg [2:0] cnt; 
    
    always@(posedge pclk  or negedge rsn) 
	if (!rsn)   cnt <= 0;
    else        cnt <= cnt + 1;
    
    reg valid_pclk;
    
    reg [31:0]  MEM_pclk;
    
    always@(posedge pclk or negedge rsn)  
    if (!rsn)   begin 
        valid_pclk  <= 0; 
        MEM_pclk    <= 0; 
    end else  if (cnt<=3) begin  
        valid_pclk <= 0; 
        MEM_pclk <= {MEM1,MEM0}; 
    end else begin   
        valid_pclk <= 1; 
    end 
    
    
	// core_clk domain 
    reg valid_core_0;
    reg valid_core_1;
    reg valid_core_2;
    
    always@(posedge pclk or negedge rsn) 
	if (!rsn)   begin 
        valid_core_0 <= 0;
        valid_core_1 <= 0;
        valid_core_2 <= 0;
    end else begin
        valid_core_0 <= valid_pclk;
        valid_core_1 <= valid_core_0;
        valid_core_2 <= valid_core_1;
    end 
    
    reg [31:0]  MEM_core_try;
    always@(posedge pclk or negedge rsn) 
	if (!rsn)  
        MEM_core_try <= 0;
    else if (valid_core_0)  
        MEM_core_try <= MEM_pclk;
     
    
    reg [31:0]  MEM_core;
    always@(posedge pclk or negedge rsn) 
	if (!rsn)  
        MEM_core <= 0;
    else if (valid_core_0&valid_core_1&valid_core_2)  
        MEM_core <= MEM_core_try;
     
    
    assign data=MEM_core[15:0];
    assign {PWM_PRD,PWM_RES,PWM_POL}=MEM_core[31:16];
    
    
    
    
endmodule

