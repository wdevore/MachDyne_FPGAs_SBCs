        // This test sequence tests setting Control bits and
        // writing to the Tx buffer to trigger transmission.


        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Enable interrupts
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMEnableInterrupts_S1: begin
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

        SMEnableInterrupts_S2: begin
            wr <= 0;    // Enable writing to component
        end

        SMEnableInterrupts_S3: begin
            wr <= 0;
        end

        SMEnableInterrupts_S4: begin
            cs <= 1;    // Disable Chip select
            wr <= 1;    // Disable writing to component
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // System requests control
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMEnableInterrupts_S5: begin
            // Set CTL_SYS_SRC bit
            in_data <= 8'h0000_0001;
            addr <= 3'b010; // Address control1 register
            cs <= 0;    // Enable Chip select
        end

        SMEnableInterrupts_S6: begin
            wr <= 0;    // Enable writing to component
        end

        SMEnableInterrupts_S7: begin
            wr <= 0;
        end

        SMEnableInterrupts_S8: begin
            cs <= 1;    // Disable Chip select
            wr <= 1;    // Disable writing to component
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Wait for Grant by polling CTL_SYS_GRNT
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Read the control2 register and transition when GRNT Set.
        SMEnableInterrupts_S9: begin
            addr <= 3'b010; // Address control2 register
            cs <= 0;    // Enable Chip select
        end

        SMEnableInterrupts_S10: begin
            component_data <= out_data;
        end

        SMEnableInterrupts_S11: begin
            cs <= 1;    // Disable chip
            if (component_data[CTL_SYS_GRNT]) begin
                $display("System has been granted control");
            end
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Now with control System can write to Tx buffer
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMEnableInterrupts_S12: begin
            in_data <= 8'h99;    // Setup data first
            addr <= 3'b100; // Address Tx register
            cs <= 0;    // Enable Chip select
        end

        SMEnableInterrupts_S13: begin
            wr <= 0;    // Enable writing to component
        end

        SMEnableInterrupts_S14: begin
            wr <= 0;
        end

        SMEnableInterrupts_S15: begin
            cs <= 1;    // Disable Chip select
            wr <= 1;    // Disable writing to component
        end
