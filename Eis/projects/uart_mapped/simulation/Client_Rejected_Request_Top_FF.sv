        // This test covers a client requesting control while the
        // System has it. The Client should be rejected.

        // First System gains control and idles
        // Then Client makes a request.


        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Enable interrupts
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMClientRejection_S1: begin
            // The proper way is to read the
            // control register first and then OR the bits with a
            // mask.
            // For example, if control1 had 
            // 8'h0101_0000
            // 8'h0000_0001  OR   <----- mask
            in_data <= 8'h0000_0001;    // We overwrite for the TB
            addr <= 3'b001; // Address control1 register
            cs <= 0;    // Enable Chip select
        end

        SMClientRejection_S2: begin
            wr <= 0;    // Enable writing to component
        end

        SMClientRejection_S3: begin
            wr <= 0;
        end

        SMClientRejection_S4: begin
            cs <= 1;    // Disable Chip select
            wr <= 1;    // Disable writing to component
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // System requests control
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMClientRejection_S5: begin
            // Set CTL_SYS_SRC bit
            in_data <= 8'h0000_0001;
            addr <= 3'b010; // Address control2 register
            cs <= 0;    // Enable Chip select
        end

        SMClientRejection_S6: begin
            wr <= 0;    // Enable writing to component
        end

        SMClientRejection_S7: begin
            wr <= 0;
        end

        SMClientRejection_S8: begin
            cs <= 1;    // Disable Chip select
            wr <= 1;    // Disable writing to component
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Wait for Grant by polling CTL_SYS_GRNT
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Read the control2 register and transition when GRNT Set.
        SMClientRejection_S9: begin
            addr <= 3'b010; // Address control2 register
            cs <= 0;    // Enable Chip select
        end

        SMClientRejection_S10: begin
            component_data <= out_data;
        end

        SMClientRejection_S11: begin
            cs <= 1;    // Disable chip
            if (component_data[CTL_SYS_GRNT]) begin
                $display("System has been granted control");
            end
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Now have client make request using UART
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Note: The device is in SystemIdle at this point.

        SMClientRejection_S12: begin
            client_tx_byte <= 8'b0000_0000;   // CRC_Signal
        end

        SMClientRejection_S13: begin
            tx_en <= 0; // Trigger transmission
        end

        SMClientRejection_S14: begin
            tx_en <= 1; // Disable trigger
            // Wait for byte from Client to complete
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Device will now send "REJ_Signal"
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // The Device should become busy while it transmits.
        // We wait for the Device busy signal to deactivate
        SMClientRejection_S15: begin
            addr <= 3'b010; // Address control2 register
            cs <= 0;    // Enable Chip select
        end

        SMClientRejection_S16: begin
            component_data <= out_data;
        end

        SMClientRejection_S17: begin
            // Default to SMClientRejection_S15
            cs <= 1;    // Disable chip select
            if (~component_data[CTL_DVC_BSY]) begin
                $display("Device is no longer busy");
                // Move to SMClientRejection_S18
            end
        end

        SMClientRejection_S18: begin
        end
        // Stop 