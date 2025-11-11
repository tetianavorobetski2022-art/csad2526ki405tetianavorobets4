// uartTx.v
// Простий UART передавач (8N1) з використанням oversample tick.
// Порти:
//  i_data  - 8-бітний байт для відправки
//  i_send  - 1-пульс/1-логічний запуск передачі (рекомендується тримати 1 такт)
//  o_tx    - серійний лінійний вихід (idle = 1)
//  o_busy  - високий поки йде передача байта
//  o_done  - короткий імпульс у циклі коли байт відправлено

module uartTx #(
    parameter integer OVERSAMPLE = 16
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tick,       // oversample tick (1 такт на oversample частоту)
    input  wire [7:0]  i_data,
    input  wire        i_send,     // подати 1 для початку передачі (пульс або рівень)
    output reg         o_tx,
    output reg         o_busy,
    output reg         o_done
);

    // --- Станова машина відправки ---
    // Замість typedef enum logic [1:0] використовуємо параметри
    parameter [1:0]
        TX_IDLE  = 2'b00,
        TX_START = 2'b01,
        TX_DATA  = 2'b10,
        TX_STOP  = 2'b11;

    reg [1:0] state;          // поточний стан
    reg [3:0] oversample_cnt; // рахує OVERSAMPLE циклів для одного біту
    reg [2:0] bit_index;      // індекс бітів (0..7)
    reg [7:0] shift_reg;      // регістр для зсуву бітів

    // --- Основний процес ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= TX_IDLE;
            o_tx           <= 1'b1;
            o_busy         <= 1'b0;
            o_done         <= 1'b0;
            oversample_cnt <= 4'd0;
            bit_index      <= 3'd0;
            shift_reg      <= 8'h00;
        end else begin
            o_done <= 1'b0; // скидаємо done сигнал, буде встановлено при завершенні передачі

            case (state)
                TX_IDLE: begin
                    o_tx   <= 1'b1;
                    o_busy <= 1'b0;
                    if (i_send) begin
                        // зберігаємо дані і переходимо на старт-біт
                        shift_reg      <= i_data;
                        oversample_cnt <= 4'd0;
                        bit_index      <= 3'd0;
                        o_busy         <= 1'b1;
                        state          <= TX_START;
                    end
                end

                TX_START: begin
                    // відправляємо старт-біт (0) протягом OVERSAMPLE тиків
                    o_tx <= 1'b0;
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE - 1)) begin
                            oversample_cnt <= 4'd0;
                            state <= TX_DATA;
                        end else begin
                            oversample_cnt <= oversample_cnt + 1'b1;
                        end
                    end
                end

                TX_DATA: begin
                    // відправка 8 бітів (LSB першим)
                    o_tx <= shift_reg[0];
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE - 1)) begin
                            oversample_cnt <= 4'd0;
                            shift_reg <= {1'b0, shift_reg[7:1]}; // зсув вправо
                            if (bit_index == 3'd7) begin
                                bit_index <= 3'd0;
                                state <= TX_STOP;
                            end else begin
                                bit_index <= bit_index + 1'b1;
                            end
                        end else begin
                            oversample_cnt <= oversample_cnt + 1'b1;
                        end
                    end
                end

                TX_STOP: begin
                    // відправляємо стоп-біт(и) = 1. Тут 1 стоп-біт.
                    o_tx <= 1'b1;
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE - 1)) begin
                            oversample_cnt <= 4'd0;
                            state <= TX_IDLE;
                            o_busy <= 1'b0;
                            o_done <= 1'b1; // повідомляємо що байт відправлено
                        end else begin
                            oversample_cnt <= oversample_cnt + 1'b1;
                        end
                    end
                end

                default: state <= TX_IDLE;
            endcase
        end
    end

endmodule
