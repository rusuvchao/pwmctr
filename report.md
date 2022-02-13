---
typora-root-url: img
---

# top-level diagram



<img src="/top.png" style="zoom:27%;" />



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



**pwm_drive@core_clk**

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

 ![img](https://hardwarebee.com/wp-content/uploads/2020/02/2_flop_cdc.jpg)



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

 





<img src="/valid ready talk.svg" style="zoom:800%;" />

<img src="/valid ready timing.png" style="zoom:50%;" />

## PWM round period

Predefinition : 

​	Suppose PWM resolution is 256

​	PWM frequency is 1kHz

As presented before, in the module



 
