        // This test covers a client requesting control while
        // neither has it. The client should be granted

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Pseudo Tx client (client_uart) makes request
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SM_S1: begin
            client_tx_byte <= 8'b0000_0000;   // CRC_Signal
        end

        SM_S2: begin
            tx_en <= 0; // Trigger transmission
        end

        SM_S3: begin
            tx_en <= 1; // Disable trigger
            // Wait for byte from Client to complete
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Wait for Grant signal from device using
        // Psuedo Rx Client
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SM_S4: begin
            if (rx_complete) begin
                $display("Client response is: %h", );
            end
        end

        SM_S5: begin
        end

        // Stop 