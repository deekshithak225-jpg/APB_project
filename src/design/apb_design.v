`default_nettype none
module apb_protocol(
    input  wire PCLK,
    input  wire PRESETn,
    input  wire transfer,
    input  wire READ_WRITE,
    input  wire [8:0] apb_write_paddr,
    input  wire [7:0] apb_write_data,
    input  wire [8:0] apb_read_paddr,
    output reg [7:0] apb_read_data_out
);
reg PSEL1,PSEL2,PENABLE,PWRITE;
reg [7:0] PADDR,PWDATA;
wire [7:0]PRDATA1,PRDATA2;
wire PREADY1,PREADY2;
wire PSLVERR1,PSLVERR2;
parameter IDLE = 2'b00,SETUP = 2'b01,ACCESS = 2'b10;
reg [1:0] state;
always @(posedge PCLK or negedge PRESETn)
begin
    if(!PRESETn)
    begin
        state<=IDLE;
        PSEL1<=0;
        PSEL2<=0;
        PENABLE<=0;
        PWRITE<=0;
        PADDR<=0;
        PWDATA<=0;
        apb_read_data_out<=0;
    end
    else
    begin
        case(state)
        IDLE:
        begin
            PENABLE<=0;
            PSEL1<=0;
            PSEL2<=0;
            if(transfer)
            begin
                state<=SETUP;
                PWRITE<=READ_WRITE;
                if(READ_WRITE)
                begin
                    PADDR<=apb_write_paddr[7:0];
                    PWDATA<=apb_write_data;
                    if(apb_write_paddr[8]==0)
                        PSEL1<=1;
                    else
                        PSEL2<=1;
                end
                else
                begin
                    PADDR<=apb_read_paddr[7:0];
                    if(apb_read_paddr[8]==0)
                        PSEL1<=1;
                    else
                        PSEL2<=1;
                end
            end
        end
        SETUP:
        begin
            PENABLE<=1;
            state<=ACCESS;
        end

       ACCESS: 
        begin
            if (PSEL1) 
            begin
                if (PREADY1) 
                begin
                    if (!PWRITE) 
                         apb_read_data_out<=PRDATA1;
                    if (transfer) 
                    begin
                        state<=SETUP;
                        PENABLE<=1'b0;
                        PWRITE<=READ_WRITE;
                        if (READ_WRITE) 
                        begin
                            PADDR<=apb_write_paddr[7:0];
                            PWDATA<=apb_write_data;
                            PSEL1<=(apb_write_paddr[8]==0);
                            PSEL2<=(apb_write_paddr[8]==1);
                        end 
                        else 
                        begin
                            PADDR<=apb_read_paddr[7:0];
                            PSEL1<=(apb_read_paddr[8]==0);
                            PSEL2<=(apb_read_paddr[8]==1);
                        end
                    end 
                    else 
                    begin
                        state<=IDLE;
                        PENABLE<=1'b0;
                        PSEL1<=1'b0;
                        PSEL2<=1'b0;
                    end
                end 
                else 
                begin
                    state<=ACCESS;
                    PENABLE<=1'b1;
                end
            end 
            else if (PSEL2) 
            begin
                if (PREADY2) 
                begin
                    if (!PWRITE) 
                        apb_read_data_out<=PRDATA2;
                    if (transfer) 
                    begin
                        state<=SETUP;
                        PENABLE<=1'b0;
                        PWRITE<=READ_WRITE;
                        if (READ_WRITE) 
                        begin
                            PADDR<=apb_write_paddr[7:0];
                            PWDATA<=apb_write_data;
                            PSEL1<=(apb_write_paddr[8]==0);
                            PSEL2<=(apb_write_paddr[8]==1);
                        end 
                        else 
                        begin
                            PADDR<=apb_read_paddr[7:0];
                            PSEL1<=(apb_read_paddr[8]==0);
                            PSEL2<=(apb_read_paddr[8]==1);
                        end
                    end 
                    else 
                    begin
                        state<=IDLE;
                        PENABLE<=1'b0;
                        PSEL1<=1'b0;
                        PSEL2<=1'b0;
                    end
                end 
                else 
                begin
                    state<=ACCESS;
                    PENABLE<=1'b1;
                end
            end
        end
              
        default:
            state <= IDLE;
        endcase
    end
end

apb_slave slave1(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL1),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA1),
    .PREADY(PREADY1),
    .PSLVERR(PSLVERR1)
);

apb_slave slave2(
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PSEL(PSEL2),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA2),
    .PREADY(PREADY2),
    .PSLVERR(PSLVERR2)
);
endmodule

module apb_slave(
    input  wire PCLK,
    input  wire PRESETn,
    input  wire PSEL,
    input  wire  PENABLE,
    input  wire  PWRITE,
    input  wire [7:0] PADDR,
    input  wire [7:0] PWDATA,
    output reg [7:0] PRDATA,
    output reg PREADY,
    output reg PSLVERR
);
reg [7:0]mem[0:255];
integer i;
always@(posedge PCLK or negedge PRESETn)
begin
    if(!PRESETn)
    begin
        PREADY<=0;
        PSLVERR<=0;
        for(i=0;i<256;i=i+1)
            mem[i]<=0;
    end
    else
    begin
        if(PSEL&&PENABLE)
        begin
            PREADY<=1;
            if(PADDR>8'hF0)
                PSLVERR<=1;
            else
            begin
                PSLVERR<=0;
                if(PWRITE)
                    mem[PADDR]<=PWDATA;
            end
        end
        else
        begin
            PREADY<=0;
            PSLVERR<=0;
        end
    end
end
always @(*)
begin
    if(!PWRITE)
        PRDATA=mem[PADDR];
    else
        PRDATA=8'h00;
end
endmodule

