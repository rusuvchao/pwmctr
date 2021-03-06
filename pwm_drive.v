
  
 module   pwm_drive
	(
		input          clk,    // 2k * 2^16  = 262.144Mhz
		input          rsn,                     
		input       [15:0]  data,      
		input       [ 3:0]  PWM_PRD, //0=0.5ms 1=0.50ms  2=0.75ms  3=1.00ms  4=1.25ms   5=1.50ms   6=1.75ms   7=2.00ms
        input       [ 2:0]  PWM_RES, //resolution: 0=12bit(default), 1=13bits,2=14bit, 3=15bit, 4=16bit;
        input               PWM_POL, // polarity, 0=idle_level_low 1=idle_level_high
       
        output reg pwm_o // filter input
         
		
	);
	
 
    reg [7:0] N;
    
    always@(*)
    begin     
        case(PWM_RES) 
                4: N= 1;
                3: N= 2;
                2: N= 4;
                1: N= 8;
          default: N= 16;
        endcase        
        case(PWM_PRD) 
                7: N=N*8; // 500hz
                6: N=N*7;
                5: N=N*6;
                4: N=N*5;
                3: N=N*4;
                2: N=N*3;
                1: N=N*2; 
          default: N=N*2;//2000hz 
        endcase
    end 
    
    
    
    // period counter for divided clock   
    // for reducing power consuming, we can add more internal clocks
    reg [7:0] clk_cnt;

    always@(posedge clk  or negedge rsn) 
	if (!rsn)               clk_cnt <= 0;
    else if (clk_cnt<(N-1)) clk_cnt <= clk_cnt + 1;
    else                    clk_cnt <= 0;   
    
    // divided clock ==   enable singnal   
    reg clk_div;
    
    always@(posedge clk  or negedge rsn) 
	if (!rsn)   clk_div <= 0;
    else        clk_div <= (clk_cnt==0) ; 
        
     
    
    
    // data moving reference
    reg [15:0] dref;
    
    always@(posedge clk_div  or negedge rsn) 
    if (!rsn)            dref <= 0;  
    else if (PWM_RES==4) dref <= dref + 1;
    else if (PWM_RES==3) dref <= dref + 2;
    else if (PWM_RES==2) dref <= dref + 4;
    else if (PWM_RES==1) dref <= dref + 2;
    else if (PWM_RES==0) dref <= dref + 1; 
 
    // pwm output
    always@(posedge clk_div  or negedge rsn) 
    if (!rsn)           pwm_o <= 0;    
    else if (PWM_POL)   pwm_o <= data > dref;  
    else                pwm_o <= data < dref;  

endmodule

