        SMIdle: begin
            next_state = SMSendKeySetup;
        end

        SMSendKeySetup: begin
            next_state = SMSendKeyTrigger;
        end

        SMSendKeyTrigger: begin
            next_state = SMSendKeyUnTrigger;
        end

        SMSendKeyUnTrigger: begin
            next_state = SMSendKeySending;
        end

        SMSendKeySending: begin
            next_state = SMSendKeySending;

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                next_state = SMSendKeyCodeSetup;
            end
        end

        SMSendKeyCodeSetup: begin
            next_state = SMSendKeyCodeTrigger;
        end

        SMSendKeyCodeTrigger: begin
            next_state = SMSendKeyCodeUnTrigger;
        end

        SMSendKeyCodeUnTrigger: begin
            next_state = SMSendKeyCodeSending;
        end

        SMSendKeyCodeSending: begin
            next_state = SMSendKeyCodeSending;

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                next_state = SMReadControl1;
            end
        end

        SMReadControl1: begin
            next_state = SMReadControl1_A;
        end

        SMReadControl1_A: begin
            next_state = SMReadControl1_B;
        end

        SMReadControl1_B: begin
            if (component_data[CTL_KEY_RDY] == 1) begin
                next_state = SMReadKeycode_A;
            end
            else
                next_state = SMStop;
        end

        SMReadKeycode_A: begin
            next_state = SMReadKeycode_B;
        end

        SMReadKeycode_B: begin
            next_state = SMReadKeycode_C;
        end

        SMReadKeycode_C: begin
            next_state = SMStop;
        end
