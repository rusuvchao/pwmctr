
  
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
    
    
    
    reg [2:0] STATE; //default wait=0/5/6/7 , ready=1, lock=2, valid=3, end=4
    wire [2:0] STATE_WAIT =0;
    wire [2:0] STATE_READY=1;
    wire [2:0] STATE_LOCK =2;
    wire [2:0] STATE_VALID=3;
    wire [2:0] STATE_END  =4;
    
    reg valid, ready;
    
    reg [31:0]  LOCK, MEMO;
    
    // pclk domain 
    reg ready_pclk;
    always@(posedge pclk or negedge rsn)  
    if (!rsn) 
        ready_pclk <= 0; 
    else 
        ready_pclk <= ready;
        
        
    always@(*)
    begin 
        
        STATE=STATE_WAIT;
        if ( (valid==0) && (ready==0)                       ) STATE=STATE_WAIT ;
        if ( (valid==0) && (ready==1) && (ready_pclk==0)    ) STATE=STATE_READY;
        if ( (valid==0) && (ready==1) && (ready_pclk==1)    ) STATE=STATE_LOCK ;
        if ( (valid==1) && (ready==1)                       ) STATE=STATE_VALID;
        if ( (valid==1) && (ready==0)                       ) STATE=STATE_END  ;
    end 
        
        
        
    always@(posedge pclk or negedge rsn)  
    if (!rsn) begin 
        valid<=0;  
        LOCK<= 0; 
    end else 
    case ( STATE )
        STATE_READY: LOCK<={MEM1,MEM0};   
        STATE_LOCK : valid<=1;
        STATE_END  : valid<=0; 
    endcase
           
   // core clk domain  
         
    always@(posedge core_clk or negedge rsn)  
    if (!rsn) begin 
        ready <= 0; 
        MEMO<=0;
    end else 
    case ( STATE )
        STATE_WAIT  :                   ready <= 1;   
        STATE_VALID : begin MEMO<=LOCK; ready <= 0;  end   
    endcase
     
    assign data=MEMO[15:0];       
    assign {PWM_PRD,PWM_RES,PWM_POL}=MEMO[31:16];
    
    
endmodule

