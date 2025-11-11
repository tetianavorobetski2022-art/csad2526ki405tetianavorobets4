`timescale 1us/1ns
// -------------------------------------------------------------
// techbanch.v
// Testbench для UART Tx/Rx з автоматичним завершенням і VCD
// -------------------------------------------------------------
module techbanch;

    localparam integer CLOCK_FREQ = 1_000_000; // 1 MHz
    localparam integer BAUD       = 9600;
    localparam integer OVERSAMPLE = 16;

    reg clk;
    reg rst_n;

    wire tx_line;
    reg  rx_line;

    reg  [7:0] tx_data;
    reg        tx_send;
    wire       tx_busy;
    wire       tx_done;

    wire [7:0] rx_data;
    wire       rx_ready;
    wire       rx_frame_err;

    wire tick;

    // ---------------------------------------------------------
    // Генерація тактового сигналу
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #0.5 clk = ~clk; // 1 MHz
    end

    // ---------------------------------------------------------
    // Генерація скидання і VCD
    // ---------------------------------------------------------
    initial begin
        $dumpfile("techbanch.vcd");
        $dumpvars(0, techbanch);
        rst_n = 0;
        #5;
        rst_n = 1;
    end

    // ---------------------------------------------------------
    // Інстанціація модулів
    // ---------------------------------------------------------
    baud #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD(BAUD),
        .OVERSAMPLE(OVERSAMPLE)
    ) u_baud (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick)
    );

    uartTx #(
        .OVERSAMPLE(OVERSAMPLE)
    ) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .i_data(tx_data),
        .i_send(tx_send),
        .o_tx(tx_line),
        .o_busy(tx_busy),
        .o_done(tx_done)
    );

    uartRx #(
        .OVERSAMPLE(OVERSAMPLE)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .tick(tick),
        .i_rx(rx_line),
        .o_data(rx_data),
        .o_data_ready(rx_ready),
        .o_frame_err(rx_frame_err)
    );

    // ---------------------------------------------------------
    // Моніторинг RX
    // ---------------------------------------------------------
    always @(posedge rx_ready) begin
        $display("[%0t us] >>> RX received byte: %h (frame_err=%b)",
                 $time, rx_data, rx_frame_err);
    end

    // ---------------------------------------------------------
    // Основний тест
    // ---------------------------------------------------------
    initial begin
        // Початкові значення
        tx_data = 8'h00;
        tx_send = 1'b0;
        rx_line = 1'b1; // idle

        // Очікуємо скидання
        wait(rst_n == 1);
        #10;

        // --- Test 1: TX ---
        $display("\n=== Test 1: TX transmission ===");
        send_byte(8'h55);
        send_byte(8'hA5);
        send_byte(8'hFF);
        send_byte(8'h00);
        $display("=== Test 1 completed ===\n");

        // --- Test 2: RX ---
        $display("=== Test 2: RX reception simulation ===");
        send_uart_byte_to_rx(8'hC1);
        send_uart_byte_to_rx(8'h7F);
        $display("=== Test 2 completed ===\n");

        #100;
        $display("=== All tests finished ===");
        $finish;
    end

    // ---------------------------------------------------------
    // Завдання: відправка байта у Tx
    // ---------------------------------------------------------
    task send_byte(input [7:0] data);
        begin
            @(posedge clk);
            tx_data <= data;
            tx_send <= 1'b1;
            @(posedge clk);
            tx_send <= 1'b0;
            wait(tx_done);
            $display("[%0t us] TX completed transmission of byte: %h", $time, data);
        end
    endtask

    // ---------------------------------------------------------
    // Завдання: імітація UART-передачі у Rx
    // ---------------------------------------------------------
task send_uart_byte_to_rx(input [7:0] data);
    integer i, j;
    begin
        // --- Старт-біт (0) ---
        rx_line = 1'b0;
        for (j = 0; j < OVERSAMPLE; j = j + 1)
            @(posedge tick);

        // --- Біти даних (MSB першим) ---
        for (i = 7; i >= 0; i = i - 1) begin
            rx_line = data[i];
            for (j = 0; j < OVERSAMPLE; j = j + 1)
                @(posedge tick);
        end

        // --- Стоп-біт (1) ---
        rx_line = 1'b1;
        for (j = 0; j < OVERSAMPLE; j = j + 1)
            @(posedge tick);

        // --- Пауза між байтами ---
        for (j = 0; j < OVERSAMPLE * 2; j = j + 1)
            @(posedge tick);
    end
endtask

endmodule
