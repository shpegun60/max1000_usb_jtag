
//
`timescale 1ns/1ps
//
module jtag_logic(
   clk                          ,
   nrxf                         ,
   ntxe                         ,
   b_tdo                        ,
   b_asdo                       ,
   b_tck                        ,
   b_tms                        ,
   b_nce                        ,
   b_ncs                        ,
   b_tdi                        ,
   b_oe                         ,
   led_n                        ,
   nrd                          ,
   wr                           ,
   d
);

////////////////////////////////////////////////////////////////////////////////
// PARAMETER DECLARE
////////////////////////////////////////////////////////////////////////////////


parameter                       WAIT_FOR_NRXF_LOW           = 4'b0000;
parameter                       SET_NRD_LOW                 = 4'b0001;
parameter                       KEEP_NRD_LOW                = 4'b0010;
parameter                       LATCH_DATA_FROM_HOST        = 4'b0011;
parameter                       SET_NRD_HIGH                = 4'b0100;
parameter                       BITS_SET_PINS_FROM_DATA     = 4'b0101;
parameter                       BYTES_SET_BITCOUNT          = 4'b0110;
parameter                       BYTES_GET_TDO_SET_TDI       = 4'b0111;
parameter                       BYTES_CLOCK_HIGH_AND_SHIFT  = 4'b1000;
parameter                       BYTES_KEEP_CLOCK_HIGH       = 4'b1001;
parameter                       BYTES_CLOCK_FINISH          = 4'b1010;
parameter                       WAIT_FOR_NTXE_LOW           = 4'b1011;
parameter                       SET_WR_HIGH                 = 4'b1100;
parameter                       OUTPUT_ENABLE               = 4'b1101;
parameter                       SET_WR_LOW                  = 4'b1110;
parameter                       OUTPUT_DISABLE              = 4'b1111;


////////////////////////////////////////////////////////////////////////////////
// I/O DECLARE
////////////////////////////////////////////////////////////////////////////////

input                           clk                         ;
input                           nrxf                        ;
input                           ntxe                        ;
input                           b_tdo                       ;
input                           b_asdo                      ;
output                          b_tck                       ;
output                          b_tms                       ;
output                          b_nce                       ;
output                          b_ncs                       ;
output                          b_tdi                       ;
output                          b_oe                        ;
output                          led_n                       ;
output                          nrd                         ;
output                          wr                          ;
inout   [7:0]                   d                           ;

////////////////////////////////////////////////////////////////////////////////
// VARIABLE DECLARE
////////////////////////////////////////////////////////////////////////////////
reg                             carry                       ;
reg                             do_output                   ;
reg     [7:0]                   ioshifter                   ;
reg     [8:0]                   bitcount                    ;
reg     [3:0]                   cur_state                   ;
reg     [3:0]                   next_state                  ;

reg                             b_tck                       ;
reg                             b_tms                       ;
reg                             b_nce                       ;
reg                             b_ncs                       ;
reg                             b_tdi                       ;
reg                             b_oe                        ;
reg                             led_n                       ;
reg                             nrd                         ;
reg                             wr                          ;
reg     [7:0]                   d                           ;
////////////////////////////////////////////////////////////////////////////////
// BEGIN OF RTL LOGIC
////////////////////////////////////////////////////////////////////////////////
always @(posedge clk)
begin
    cur_state                   <= next_state;
end

always @(*)
begin
    case(cur_state)
        WAIT_FOR_NRXF_LOW:
        begin
            if(nrxf==1'b0)
            begin
                next_state      = SET_NRD_LOW;
            end
            else
            begin
                next_state      = WAIT_FOR_NRXF_LOW;
            end
        end
        SET_NRD_LOW:
        begin
            next_state          = KEEP_NRD_LOW;
        end
        KEEP_NRD_LOW:
        begin
            next_state          = LATCH_DATA_FROM_HOST;
        end
        LATCH_DATA_FROM_HOST:
        begin
            next_state          = SET_NRD_HIGH;
        end
        SET_NRD_HIGH:
        begin
            if(bitcount[8:3]!=6'h0)
            begin
                next_state      = BYTES_GET_TDO_SET_TDI;
            end
            else if(ioshifter[7]==1'b1)
            begin
                next_state      = BYTES_SET_BITCOUNT;
            end
            else
            begin
                next_state      = BITS_SET_PINS_FROM_DATA;
            end
        end
        BYTES_SET_BITCOUNT:
        begin
            next_state          = WAIT_FOR_NRXF_LOW;
        end
        BITS_SET_PINS_FROM_DATA:
        begin
            if(ioshifter[6]==1'b0)
            begin
                next_state      = WAIT_FOR_NRXF_LOW;
            end
            else
            begin
                next_state      = WAIT_FOR_NTXE_LOW;
            end
        end
        BYTES_GET_TDO_SET_TDI:
        begin
            next_state          = BYTES_CLOCK_HIGH_AND_SHIFT;
        end
        BYTES_CLOCK_HIGH_AND_SHIFT:
        begin
            next_state          = BYTES_KEEP_CLOCK_HIGH;
        end
        BYTES_KEEP_CLOCK_HIGH:
        begin
            next_state          = BYTES_CLOCK_FINISH;
        end
        BYTES_CLOCK_FINISH:
        begin
            if(bitcount[2:0]!=3'b111)
            begin
                next_state      = BYTES_GET_TDO_SET_TDI;
            end
            else if(do_output==1'b1)
            begin
                next_state      = WAIT_FOR_NTXE_LOW;
            end
            else
            begin
                next_state      = WAIT_FOR_NRXF_LOW;
            end
        end
        WAIT_FOR_NTXE_LOW:
        begin
            if(ntxe==1'b0)
            begin
                next_state      = SET_WR_HIGH;
            end
            else
            begin
                next_state      = WAIT_FOR_NTXE_LOW;
            end
        end
        SET_WR_HIGH:
        begin
            next_state          = OUTPUT_ENABLE;
        end
        OUTPUT_ENABLE:
        begin
            next_state          = SET_WR_LOW;
        end
        SET_WR_LOW:
        begin
            next_state          = OUTPUT_DISABLE;
        end
        OUTPUT_DISABLE:
        begin
            next_state          = WAIT_FOR_NRXF_LOW;
        end
        default:
        begin
            next_state          = WAIT_FOR_NRXF_LOW;
        end
    endcase
end

always @(posedge clk)
begin
    if(cur_state==SET_NRD_LOW || cur_state==KEEP_NRD_LOW || cur_state==LATCH_DATA_FROM_HOST)
    begin
        nrd                     <= 1'b0;
    end
    else
    begin
        nrd                     <= 1'b1;
    end
    if(cur_state==LATCH_DATA_FROM_HOST)
    begin
        ioshifter               <= d;
    end
    if(cur_state==SET_WR_HIGH || cur_state==OUTPUT_ENABLE)
    begin
        wr                      <= 1'b1;
    end
    else
    begin
        wr                      <= 1'b0;
    end
    if(cur_state==OUTPUT_ENABLE || cur_state==SET_WR_LOW)
    begin
        d                       <= ioshifter;
    end
    else
    begin
        d                       <= 8'hz;
    end
    if(cur_state==BITS_SET_PINS_FROM_DATA)
    begin
        b_tck                   <= ioshifter[0];
        b_tms                   <= ioshifter[1];
        b_nce                   <= ioshifter[2];
        b_ncs                   <= ioshifter[3];
        b_tdi                   <= ioshifter[4];
        b_oe                    <= ioshifter[5];
        led_n                   <= !ioshifter[5];
        ioshifter               <= {6'h0,b_asdo,b_tdo};
    end
    if(cur_state==BYTES_SET_BITCOUNT)
    begin
        bitcount                <= {ioshifter[5:0],3'b111};
        do_output               <= ioshifter[6];
    end
    if(cur_state==BYTES_GET_TDO_SET_TDI)
    begin
        if(b_ncs==1'b1)
        begin
            carry               <= b_tdo;
        end
        else
        begin
            carry               <= b_asdo;
        end
        b_tdi                   <= ioshifter[0];
        bitcount                <= bitcount - 9'h1;
    end
    if(cur_state==BYTES_CLOCK_HIGH_AND_SHIFT || cur_state==BYTES_KEEP_CLOCK_HIGH)
    begin
        b_tck                   <= 1'b1;
    end
    if(cur_state==BYTES_CLOCK_HIGH_AND_SHIFT)
    begin
        ioshifter               <= {carry,ioshifter[7:1]};
    end
    if(cur_state==BYTES_CLOCK_FINISH)
    begin
        b_tck                   <= 1'b0;
    end
end
////////////////////////////////////////////////////////////////////////////////
// END OF RTL LOGIC
////////////////////////////////////////////////////////////////////////////////
endmodule
