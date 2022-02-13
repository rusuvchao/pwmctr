---
typora-root-url: img
---

# top-level diagram



<img src="/../report.assets/top.png" style="zoom:27%;" />



**apb_slave@pclk**

- read/write MEM which storing configuration parameters and pwm new data

- Simplify: pslverr  = 0;  pready   = 1;  

  ​		Because: data refresh rate is far slower than the clock

- if  (psel&penable) read/write MEM



**pwm_config@(pclk&core_clk)**

- clock domain crossing for MEM
- decoder from MEM byte to working data&configuration
  - data=MEM[0];
  - {PWM_PRD,PWM_RES,PWM_POL}=MEM[1];



**pwm_drive@core_clk**  (low power design)

- generate sub-clock for PWM signal
  - generate a reference signal that  increments@subclock
- encoder for PWM
  - if data>reference, pwm_o=>1 when PWM_POL=0





# Points to discuss

## CORE clock frequency 

The minimal clock dispends on:

- **PWM maximum resolution** 


$$
RES\leq2^{16}
$$

- **PWM minimum period**

  PWM frequency is firstly required in the specs as:  
  
  $$
  2kHz,1.75kHz,1.5kHz,1.25kHz, 1KHz,0.75kHz,0.5KHz
  $$
  
  The minimal frequency of the master clock needed should be the LCM(Least Common Multiple) of this frequency. It is  $210khz$ which is too large.
  
  We change the specs: PWM frequency is then required as period: 
  $$
  0.5ms,0.75ms,1ms,1.25ms, 1.50ms,1.75ms,2ms
  $$
  
  
   then the LCM thus minimal frequency is :

$$
f_{PWM}\geq  4kHz
$$

- **Minimal core clock frequency**
  $$
  f_{ck}={RES}\cdot{f_{PWM}}\geq  2^{16}\times4\times10^{3}  =262.144Mhz
  $$
  

## ASYNC 

If the APB clock and core clock come from individual sources, we always need to add some clock domain crossing  technique. In general all the techniques are some compromise of 

- Metastable /Accuracy(statistically)
- Delay, the signal is large delayed after crossing clock domain
- Clear sequence, if several-bit data are transferred in parrel, all sequence of all the bits  can not be changed .

**2FF technique** for 1 bit

If the two asyn clocks rising nearly at the same time, the reader can not be 100% sure that it can read the signal, that is called metasatble. For the purpose of getting stable and accurate signals, we can implement double sampling (or called 2FF) to highly(nearly 100%) decrease the possibility that the metastable occurs.  

 ![img](/../report.assets/2_flop_cdc.jpg)



The 2FF technique increase the  delay a little (acceptable).

**Feed back valid** 

but if the data are several bits in serial,  someone suggests some feedback handshake technology.  It is build on the 2FF structure, but add a feedback signal. The reader send back the read data to writer, the writer send a valid signal to reader when  the original data and the feedback data are fully matching.   The disadvantage is that it will increase large delay. Another issue is that the refresh rate of the delay is too large, the signals will never match. Some 



**Read at the stable time** 

1. Ready: The basic structure is that the reader send a 1bit ready signal to writer to indicate that I am ready to receive new data. 
2. Lock: The writer then (if need to send) lock the data in a register that will not change until the reader has read it.
3. Valid: send a 1bit valid signal to reader to inform the reader that you can read.
4. Read:  The reader read the data from the locked register and low down the ready signal to indicate that I have already read.
5. End: The writer low down the valid signal to let another transfer round can be started.

the advantage is that 

1. do not need 2FF, thus saving delay
2. The two clock can be at any frequency.
3. Clear control of data sequence, each transfer round transfer one time signal at the same time. 

 





<img src="/../report.assets/valid ready talk.svg" style="zoom:800%;" />

<img src="/../report.assets/valid ready timing.png" style="zoom:100%;" />

```verilog

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
```



## PWM duty cycle

**Predefinition** : 

- Suppose PWM resolution is 256
- PWM frequency is 1kHz

As presented before, in the module there is 

$subclock = coresClock  \div (2^{16bit-8bit}) \div (4kHz/1kHz)$

generate a reference signal $dref$ that  increments@subclock , from 0 to 255



$dutyCycle=\frac{data}{256}$, 

if the data=0, the pwm $dutyCycle=\frac{0}{256}$, 

if the data=255, the pwm $dutyCycle=\frac{255}{256}$



it give a stable signal that the pwm frequency cannot be detected, we need a small thin glitch signal to represent pwm frequency: 

$dutyCycle=\frac{data+1}{257}$, 

if the data=0, the pwm $dutyCycle=\frac{1}{257}$, 

if the data=255, the pwm $dutyCycle=\frac{256}{257}$

​			BTW:  if the clock does not change, the pwm frequency will be slightly decreased. sometimes can be ignored. 





## PWM application for FPGA (low area, high power implementation)

If the power is not an issue, it is better the PWM run at core clock rather than generated subclock.

- The RESOLUTION is fixed at 16bit internally. the  $dref$ that  increments@coreClock , from 0 to 65536, the resolution only used for how many bit MSB should be read from input data
-  Generated a new $dref2=dref*N$, N=1 when 0.25ms, N=8 when 2ms, remove the  carry
- Comparing $dref2$ with $data$ to get pwm_o

```verilog
 
reg [15:0] dref;
 
always@(posedge clk  or negedge rsn) 
    if (!rsn)           dref <= 0;       
    else                dref <= dref + 1;  

reg [15:0] dref2=dref * (RES+1);

always@(posedge clk_div  or negedge rsn) 
    if (!rsn)           pwm_o <= 0;    
    else if (PWM_POL)   pwm_o <= data > dref;  
    else                pwm_o <= data < dref;  
 
```

the surface is much smaller than the original one.



## 
