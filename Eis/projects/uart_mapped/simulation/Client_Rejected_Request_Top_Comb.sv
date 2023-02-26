        SMIdle: begin
            next_state = SMClientRejection_S1;
        end

        // --------------------------------------------
        SMClientRejection_S1: begin
            next_state = SMClientRejection_S2;
        end

        SMClientRejection_S2: begin
            next_state = SMClientRejection_S3;
        end

        SMClientRejection_S3: begin
            next_state = SMClientRejection_S4;
        end

        SMClientRejection_S4: begin
            next_state = SMClientRejection_S5;
        end

        // --------------------------------------------
        SMClientRejection_S5: begin
            next_state = SMClientRejection_S6;
        end

        SMClientRejection_S6: begin
            next_state = SMClientRejection_S7;
        end

        SMClientRejection_S7: begin
            next_state = SMClientRejection_S8;
        end

        SMClientRejection_S8: begin
            next_state = SMClientRejection_S9;

            // // Wait for the byte to finish transmitting.
            // if (tx_complete) begin
            //     next_state = SMReadControl1;
            // end
        end

        // --------------------------------------------
        SMClientRejection_S9: begin
            next_state = SMClientRejection_S10;
        end

        SMClientRejection_S10: begin
            next_state = SMClientRejection_S11;
        end

        SMClientRejection_S11: begin
            next_state = SMClientRejection_S11;

            if (component_data[CTL_SYS_GRNT]) begin
                next_state = SMClientRejection_S12;
            end
        end

        // --------------------------------------------
        SMClientRejection_S12: begin
            next_state = SMClientRejection_S13;
        end

        SMClientRejection_S13: begin
            next_state = SMClientRejection_S13;

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                next_state = SMClientRejection_S14;
            end
        end

        SMClientRejection_S14: begin
            next_state = SMClientRejection_S15;
        end

        // --------------------------------------------
        SMClientRejection_S15: begin
            next_state = SMClientRejection_S16;
        end

        SMClientRejection_S16: begin
            next_state = SMClientRejection_S17;
        end

        SMClientRejection_S17: begin
            next_state = SMClientRejection_S15;

            if (~component_data[CTL_DVC_BSY]) begin
                next_state = SMClientRejection_S18;
            end
        end

        // --------------------------------------------
        SMClientRejection_S18: begin
            next_state = SMStop;
        end
