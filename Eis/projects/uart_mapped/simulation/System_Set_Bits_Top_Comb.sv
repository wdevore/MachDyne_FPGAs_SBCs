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
        // -------------------------------------------

        SMEnableInterrupts_S16: begin
            next_state = SMEnableInterrupts_S17;
        end

        SMEnableInterrupts_S17: begin
            next_state = SMEnableInterrupts_S18;
        end

        SMEnableInterrupts_S18: begin
            next_state = SMEnableInterrupts_S16;

            if (component_data[CTL_TRX_CMP]) begin
                next_state = SMEnableInterrupts_S19;
            end
        end
        // -------------------------------------------

        SMEnableInterrupts_S19: begin
            next_state = SMEnableInterrupts_S20;
        end

        SMEnableInterrupts_S20: begin
            next_state = SMEnableInterrupts_S21;
        end

        SMEnableInterrupts_S21: begin
            next_state = SMEnableInterrupts_S22;
        end

        SMEnableInterrupts_S22: begin
            next_state = SMEnableInterrupts_S23;
        end

        // -------------------------------------------
        SMEnableInterrupts_S23: begin
            next_state = SMEnableInterrupts_S24;
        end

        SMEnableInterrupts_S24: begin
            next_state = SMEnableInterrupts_S25;
        end

        SMEnableInterrupts_S25: begin
            next_state = SMEnableInterrupts_S23;

            if (component_data[CTL_TRX_CMP]) begin
                next_state = SMEnableInterrupts_S26;
            end
        end

        SMEnableInterrupts_S26: begin
            next_state = SMStop;
        end
