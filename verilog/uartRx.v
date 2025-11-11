module uartRx #(
    parameter integer OVERSAMPLE = 16
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        tick,         // oversample tick
    input  wire        i_rx,         // серійний вхід (idle=1)
    output reg [7:0]   o_data,       // прийнятий байт (MSB-first)
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
    reg [4:0] oversample_cnt;  // лічильник тиків (ширший для MSB-first)
    reg [2:0] bit_index;       // індекс біта (0..7)
    reg [7:0] shift_reg;       // прийняті біти
    reg       rx_sync;         // синхронізований вхід
    reg       rx_sync_0;       // проміжний регістр для синхронізації

    // --- Синхронізація входу ---
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
            oversample_cnt <= 0;
            bit_index      <= 0;
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
                        oversample_cnt <= 0;
                        state <= RX_START;
                    end
                end

                RX_START: begin
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE/2 - 1)) begin
                            oversample_cnt <= 0;
                            if (!rx_sync) begin
                                bit_index <= 0;
                                state <= RX_DATA;
                            end else begin
                                state <= RX_IDLE; // false start
                            end
                        end else begin
                            oversample_cnt <= oversample_cnt + 1;
                        end
                    end
                end

                RX_DATA: begin
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE - 1)) begin
                            oversample_cnt <= 0;
                            // MSB-first: новий біт у старший біт
                            shift_reg <= {shift_reg[6:0], rx_sync};
                            bit_index <= bit_index + 1;
                            if (bit_index == 7) state <= RX_STOP;
                        end else begin
                            oversample_cnt <= oversample_cnt + 1;
                        end
                    end
                end

                RX_STOP: begin
                    if (tick) begin
                        if (oversample_cnt == (OVERSAMPLE - 1)) begin
                            oversample_cnt <= 0;
                            o_data <= shift_reg;
                            o_data_ready <= 1'b1;
                            o_frame_err <= ~rx_sync; // стоп-біт повинен бути 1
                            state <= RX_IDLE;
                        end else begin
                            oversample_cnt <= oversample_cnt + 1;
                        end
                    end
                end

                default: state <= RX_IDLE;
            endcase
        end
    end

endmodule
