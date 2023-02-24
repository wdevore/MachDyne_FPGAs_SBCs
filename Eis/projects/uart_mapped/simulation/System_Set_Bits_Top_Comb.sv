        SMIdle: begin
            next_state = SMEnableInterrupts_S1;
        end

        SMEnableInterrupts_S1: begin
            next_state = SMEnableInterrupts_S2;
        end

        SMEnableInterrupts_S2: begin
            next_state = SMEnableInterrupts_S3;
        end

        SMEnableInterrupts_S3: begin
            next_state = SMEnableInterrupts_S4;
        end

        SMEnableInterrupts_S4: begin
            next_state = SMEnableInterrupts_S5;
        end

        SMEnableInterrupts_S5: begin
            next_state = SMEnableInterrupts_S6;
        end

        SMEnableInterrupts_S6: begin
            next_state = SMEnableInterrupts_S7;
        end

        SMEnableInterrupts_S7: begin
            // next_state = SMEnableInterrupts_S7;

            // Wait for the byte to finish transmitting.
            // if (tx_complete) begin
                next_state = SMEnableInterrupts_S8;
            // end
        end

        SMEnableInterrupts_S8: begin
            next_state = SMEnableInterrupts_S9;
        end

        SMEnableInterrupts_S9: begin
            next_state = SMEnableInterrupts_S10;
        end

        SMEnableInterrupts_S10: begin
            next_state = SMEnableInterrupts_S11;
        end

        SMEnableInterrupts_S11: begin
            next_state = SMEnableInterrupts_S11;

            if (component_data[CTL_SYS_GRNT]) begin
                next_state = SMEnableInterrupts_S12;
            end
        end

        SMEnableInterrupts_S12: begin
            next_state = SMEnableInterrupts_S13;
        end

        SMEnableInterrupts_S13: begin
            next_state = SMEnableInterrupts_S14;
        end

        SMEnableInterrupts_S14: begin
            next_state = SMEnableInterrupts_S15;
        end

        SMEnableInterrupts_S15: begin
            next_state = SMEnableInterrupts_S16;
        end

        SMEnableInterrupts_S16: begin
            next_state = SMStop;
        end
