        // __--__##__--__##__--__##__--__##__--__##__--__##__--__##
        // Send Key-code
        // __--__##__--__##__--__##__--__##__--__##__--__##__--__##
        // At this point the component is idling.
        // We simulate a Client sending a key-code pair: 0x70 and 0x42

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Send key signal
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMSendKeySetup: begin
            tx_byte <= 8'h70;   // KEY_Signal
        end

        SMSendKeyTrigger: begin
            tx_en <= 0; // Trigger transmission
        end

        SMSendKeyUnTrigger: begin
            tx_en <= 1; // Disable trigger
        end

        SMSendKeySending: begin
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Send key code
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMSendKeyCodeSetup: begin
            tx_byte <= 8'h42;   // Ascii
        end

        SMSendKeyCodeTrigger: begin
            tx_en <= 0; // Trigger transmission
        end

        SMSendKeyCodeUnTrigger: begin
            tx_en <= 1; // Disable trigger
        end

        SMSendKeyCodeSending: begin
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Read control1 for key ready signal
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMReadControl1: begin
            addr <= 3'b001; // Address control1 register
            cs <= 0;    // Chip select active
        end

        SMReadControl1_A: begin
            component_data <= out_data;
        end

        SMReadControl1_B: begin
            cs <= 1;    // Disable chip
            if (component_data[CTL_KEY_RDY] == 0) begin
                $display("!!!!!!! Expected CTL_KEY_RDY to be Set !!!!!!!");
                $exit();
            end
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Read key-code
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMReadKeycode_A: begin
            addr <= 3'b000; // Address key-code register
            cs <= 0;    // Chip select active
        end

        SMReadKeycode_B: begin
            component_data <= out_data;
        end
        
        SMReadKeycode_C: begin
            cs <= 1;    // Disable chip
        end
