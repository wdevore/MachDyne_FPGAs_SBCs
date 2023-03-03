        // This test covers a client requesting control while
        // neither has it. The client should be granted

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Pseudo Tx client (client_uart) makes request
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SM_S1: begin
            client_tx_byte <= {CRC_Signal, 4'b0000};   // CRC_Signal
        end

        SM_S2: begin
            tx_en <= 0; // Trigger transmission
        end

        SM_S3: begin
            tx_en <= 1; // Disable trigger
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Wait for Grant signal from device using
        // Psuedo Rx Client
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SM_S4: begin
            if (rx_complete) begin
                $display("Client response is: %h", rx_byte);
            end
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Psuedo Rx Client sends BOS signal
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SM_S5: begin
            client_tx_byte <= {BOS_Signal, 4'b0000};
        end

        SM_S6: begin
            tx_en <= 0; // Trigger transmission
        end

        SM_S7: begin
            tx_en <= 1; // Disable trigger
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Psuedo Rx Client sends EOS signal
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // This should send us back to Device idle
        SM_S8: begin
            client_tx_byte <= {EOS_Signal, 4'b0000};
        end

        SM_S9: begin
            tx_en <= 0; // Trigger transmission
        end

        SM_S10: begin
            tx_en <= 1; // Disable trigger
        end

        SM_S11: begin
        end

        SM_S12: begin
            // move to stop
        end

        // Stop 