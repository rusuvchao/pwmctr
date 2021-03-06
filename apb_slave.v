
  
 module   apb_slave
	(
		 
		input               pclk        ,
		input               rsn         ,
		input [31:0]        paddr       ,
		input [15:0]        pwdata      ,
		input               pwrite      ,
		input               psel        ,
		input               penable     ,
		input [1:0]         pstrb       ,
		output reg [15:0]   prdata      ,
		input               pready      ,
		output              pslverr     ,
        
        output reg [15:0]   MEM0,
        output reg [15:0]   MEM1 



	);
    assign pslverr  = 0;
    assign pready   = 1;
    
    
    
    always@(posedge pclk or negedge rsn)  
    if (!rsn)   begin 
        MEM0    <= 0;
        MEM1    <= 0;
        prdata  <= 0;
    end else if (psel&penable) begin 
        if (pwrite)  begin 
            if      ( (paddr==32'd0) && (pstrb[0]==1) ) MEM0[ 7:0] <= pwdata[7:0];            
            else if ( (paddr==32'd0) && (pstrb[1]==1) ) MEM0[15:8] <= pwdata[7:0];
            else if ( (paddr==32'd1) && (pstrb[0]==1) ) MEM1[ 7:0] <= pwdata[7:0];            
            else if ( (paddr==32'd1) && (pstrb[1]==1) ) MEM1[15:8] <= pwdata[7:0];
        end else if (!pwrite) begin 
            if      ( (paddr==32'd0)  ) prdata <= MEM0;   
            else if ( (paddr==32'd1)  ) prdata <= MEM1;         
        end 
    end
    
    
    
    
    
endmodule

