// uartRx.v
// Простий UART приймач (8N1) з oversample tick.
// Логіка:
//  - Стан IDLE: чекаємо на спад (start bit)
//  - При детекції старту: чекаємо OVERSAMPLE/2 тиків для mid-bit вибірки,
//    потім знімаємо кожен біт з інтервалом OVERSAMPLE тиків.
//  - Після 8 бітів перевіряємо стоп-біт (повинен бути 1).

module uartRx #(
    parameter integer OVERSAMPLE = 16
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tick,         // oversample tick
    input  wire        i_rx,         // серійний вхід (idle=1)
    output reg [7:0]   o_data,       // прийнятий байт
    output reg         o_data_ready, // імпульс коли байт готовий
    output reg         o_frame_err   // фреймінг помилка (стоп-біт не 1)
);

    // --- Оголошення станів ---
    parameter [1:0]
        RX_IDLE  = 2'b00,
        RX_START = 2'b01,
        RX_DATA  = 2'b10,
        RX_STOP  = 2'b11;

    reg [1:0] state;           // поточний стан
    reg [3:0] oversample_cnt;  // лічильник тиків
    reg [2:0] bit_index;       // індекс біта (0..7)
    reg [7:0] shift_reg;       // прийняті біти
    reg       rx_sync;         // синхронізований вхід
    reg       rx_sync_0;       // проміжний регістр для синхронізації

    // --- Синхронізація входу (анти-метастабільність) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_0 <= 1'b1;
            rx_sync   <= 1'b1;
        end else begin
            rx_sync_0 <= i_rx;
            rx_sync   <= rx_sync_0;
        end
    end

    // --- Головна станова машина ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= RX_IDLE;
            oversample_cnt <= 4'd0;
            bit_index      <= 3'd0;
            shift_reg      <= 8'h00;
            o_data         <= 8'h00;
            o_data_ready   <= 1'b0;
            o_frame_err    <= 1'b0;
        end else begin
            o_data_ready <= 1'b0; // короткий імпульс при готовності

            case (state)
                RX_IDLE: begin
                    o_frame_err <= 1'b0;
                    if (!rx_sync) begin
                        // побачили спад — початок старт біта
                        oversample_cnt <= 4'd0;
                        state <= RX_START;
                    end
                end

                RX_START: begin
                    // чекаємо половину OVERSAMPLE для вибірки посередині старт біта
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE/2 - 1)) begin
                            oversample_cnt <= 4'd0;
                            if (!rx_sync) begin
                                // підтверджений старт-біт
                                bit_index <= 3'd0;
                                state <= RX_DATA;
                            end else begin
                                // хибний старт, повертаємось у IDLE
                                state <= RX_IDLE;
                            end
                        end else begin
                            oversample_cnt <= oversample_cnt + 1'b1;
                        end
                    end
                end

                RX_DATA: begin
                    // приймаємо 8 бітів (LSB першим)
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE - 1)) begin
                            oversample_cnt <= 4'd0;
                            shift_reg <= {shift_reg[6:0], rx_sync}; // зсув вліво і додавання нового біта
                            if (bit_index == 3'd7) begin
                                bit_index <= 3'd0;
                                state <= RX_STOP;
                            end else begin
                                bit_index <= bit_index + 1'b1;
                            end
                        end else begin
                            oversample_cnt <= oversample_cnt + 1'b1;
                        end
                    end
                end

                RX_STOP: begin
                    // перевірка стоп-біта (повинен бути 1)
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE - 1)) begin
                            oversample_cnt <= 4'd0;
                            if (rx_sync == 1'b1) begin
                                o_data <= shift_reg;
                                o_data_ready <= 1'b1;
                                o_frame_err <= 1'b0;
                            end else begin
                                o_data <= shift_reg;
                                o_data_ready <= 1'b1;
                                o_frame_err <= 1'b1; // помилка
                            end
                            state <= RX_IDLE;
                        end else begin
                            oversample_cnt <= oversample_cnt + 1'b1;
                        end
                    end
                end

                default: state <= RX_IDLE;
            endcase
        end
    end

endmodule
