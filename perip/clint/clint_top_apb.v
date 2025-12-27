
module clint_top_apb(
    input           clock,	        
    input           reset,	            
    input           in_psel   ,	    
    input           in_penable,	
    input           in_pwrite ,	    
    input  [31:0]   in_paddr  ,	
    input  [2:0]    in_pprot  ,	
    input  [31:0]   in_pwdata ,	
    input  [3:0]    in_pstrb  ,	
    output          in_pready ,	
    output          in_pslverr,	
    output [31:0]   in_prdata 
);

    localparam IDLE     = 0;
    localparam WRITE    = 1;
    localparam READ     = 2;

    // reg     [31:0]      m_time_low;
    // reg     [31:0]      m_time_high;
    reg     [63:0]      m_time;

    reg     [3:0]       current_state;
    reg     [3:0]       next_state;

    reg     [31:0]      r_data;

    wire    [3:0]       addr = in_paddr[3:0];

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            current_state   <= IDLE;
        end
        else begin
            current_state   <= next_state;
        end
    end

    always @(*) begin

        case(current_state)
            
            IDLE: begin
                if(in_psel == 1'b1 && in_pwrite == 1'b1) begin
                   next_state   = WRITE; 
                end
                else if(in_psel == 1'b1 && in_pwrite == 1'b0) begin
                    next_state   = READ;
                end
                else begin
                    next_state   = IDLE;
                end
            end

            WRITE: begin
                if(in_penable) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = WRITE;
                end 
            end

            READ: begin
                if(in_penable) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            m_time  <= 64'h00000000;
        end
        else  begin
            if(current_state == WRITE) begin
                if(addr == 4'h0) begin
                    m_time  <= {m_time[63:32], in_pwdata};
                end
                else if(addr == 4'h4) begin
                    m_time  <= {in_pwdata, m_time[31:0]};
                end
            end
            else begin
                m_time  <= m_time + 1;
            end
        end
    end

    always @(*) begin
        if(current_state == READ) begin
            if(addr == 4'h0) begin
                r_data = m_time[31:0];
            end
            else if(addr == 4'h4) begin
                r_data = m_time[63:32];
            end
            else begin
                r_data = 32'h0000;
            end
        end
        else begin
            r_data = 32'h0000;
        end
    end

    assign in_pready = (current_state == WRITE || current_state == READ);
    assign in_pslverr = 1'b0;
    assign in_prdata = r_data;

endmodule 
