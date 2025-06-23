module uart_top #(
    parameter CLK_FRE         = 50,
    parameter UART_RATE       = 115200
    )(
    input         i_sys_clk,    //系统时钟
    input         i_rst_n,     //系统复位
    
    input         i_uart_rx,
    output        o_uart_tx
);

typedef enum logic [1:0] {IDLE, LOOP}STATE_TOP;
STATE_TOP state;

logic [ 7:0] send_cnt;
logic [ 7:0] send_data;
logic        send_en;
logic        send_busy;

logic [ 7:0] recv_data;
logic        recv_en;

//仲裁机制
always@(posedge i_sys_clk)begin
    if(!i_rst_n)begin
        send_cnt    <= 'd0;
        send_en     <= 'b0;
        send_data   <= 'b0;

        state       <= IDLE;
    end else begin
        case(state)
            IDLE:begin // 空闲状态
                if(recv_en)begin // 接收数据
                    send_en     <= 'b1;
                    send_data   <= recv_data;

                    state       <= LOOP;
                end
            end

            LOOP:begin // 回环测试
                if(!send_busy)begin
                    send_en     <= 'b0;
                    
                    state       <= IDLE;
                end
            end

            default:begin // 默认状态
                state       <= IDLE;
            end
        endcase
    end
end

//发送模块
uart_tx #(
    .CLK_FRE            (CLK_FRE           ),
    .UART_RATE          (UART_RATE         )
)uart_tx_m0(
    .i_sys_clk          (i_sys_clk         ),
    .i_rst_n            (i_rst_n           ),

    .i_send_en          (send_en           ),
    .o_send_busy        (send_busy         ),
    .i_send_data        (send_data         ),

    .o_tx_pin           (o_uart_tx         )
);

//接收模块
uart_rx #(
    .CLK_FRE            (CLK_FRE            ),
    .UART_RATE          (UART_RATE          )
)uart_rx_m0(
    .i_sys_clk          (i_sys_clk          ),

    .o_recv_en          (recv_en            ),
    .o_recv_data        (recv_data          ),

    .i_rx_pin           (i_uart_rx          )
);

endmodule