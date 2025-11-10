// baud.v
// Генератор імпульсів для UART з оверсемплінгом.
// Параметри:
//  CLOCK_FREQ  - частота системного годинника (Hz)
//  BAUD        - бажана швидкість UART (бод)
//  OVERSAMPLE  - множник оверсемплінгу (наприклад 16)
// Вихід tick видає імпульс з частотою BAUD * OVERSAMPLE.

module baud #(
    parameter integer CLOCK_FREQ = 50000000, // 50 MHz
    parameter integer BAUD       = 115200,
    parameter integer OVERSAMPLE = 16
) (
    input  wire clk,      // системний годинник
    input  wire rst_n,    // активний низький скидання
    output reg  tick      // одноцикловий імпульс на кожен oversample tick
);

    // Обчислення кількості тактів системного годинника на 1 oversample-tick.
    // Якщо значення неціле, використовується ціла частина (integer division).
    localparam integer CLKS_PER_TICK = CLOCK_FREQ / (BAUD * OVERSAMPLE);

    // Розрядність лічильника
    localparam integer CNT_WIDTH = $clog2(CLKS_PER_TICK > 0 ? CLKS_PER_TICK : 1);

    reg [CNT_WIDTH-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tick    <= 1'b0;
        end else begin
            if (counter == CLKS_PER_TICK-1) begin
                counter <= 0;
                tick    <= 1'b1; // генеруємо одноцикловий імпульс
            end else begin
                counter <= counter + 1;
                tick    <= 1'b0;
            end
        end
    end

endmodule
