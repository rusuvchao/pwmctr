

`define ASYNC 1
  
 module   pwm_ctr
	(
		 
		input               pclk        ,
		input               preset_n         ,
		input [31:0]        paddr       ,
		input [15:0]        pwdata      ,
		input               pwrite      ,
		input               psel        ,
		input               penable     ,
		input [1:0]         pstrb       ,
		output [15:0]       prdata      ,
		input               pready      ,
		output              pslverr     ,
        
        input               core_clk,
        input               core_rst_n,
        
        output              pwm_o



	);
    
    
    
    wire pclk_swich = (`ASYNC)? pclk :  core_clk;
    
    
    wire rsn = (`ASYNC)? preset_n&core_rst_n :  core_rst_n;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
     
    wire [15:0]   MEM0;
    wire [15:0]   MEM1; 
    
    apb_slave apb_slave
	(
		 
		pclk_swich        ,
		rsn         ,
		paddr       ,
		pwdata      ,
		pwrite      ,
		psel        ,
		penable     ,
		pstrb       ,
		prdata      ,
		pready      ,
		pslverr     ,        
        MEM0,
        MEM1 );
        
        
    wire [15:0] data;         
    wire [ 3:0] PWM_PRD; //0=0.5ms 1=0.50ms  2=0.75ms  3=1.00ms  4=1.25ms   5=1.50ms   6=1.75ms   7=2.00ms   
    wire [ 2:0] PWM_RES; //resolution: 0=12bit(default), 1=13bits,2=14bit, 3=15bit, 4=16bit;   
    wire        PWM_POL; // polarity, 0=idle_level_low 1=idle_level_high   
        
        

    pwm_config pwm_config
	(
		pclk_swich,      
        core_clk,   
		rsn,     

        //pclk domain
        MEM0,
        MEM1, 
        
        //core clk domain    
		data,      
		PWM_PRD,
        PWM_RES,
        PWM_POL 
        );

    pwm_drive pwm_drive
	(
		core_clk,    // 4k * 2^16  = 262.144Mhz
		rsn,                     
		data,      
		PWM_PRD, //0=0.5ms 1=0.50ms  2=0.75ms  3=1.00ms  4=1.25ms   5=1.50ms   6=1.75ms   7=2.00ms
        PWM_RES, //resolution: 0=12bit(default), 1=13bits,2=14bit, 3=15bit, 4=16bit;
        PWM_POL, // polarity, 0=idle_level_low 1=idle_level_high
        pwm_o    // filter input
         
	);
    
endmodule

