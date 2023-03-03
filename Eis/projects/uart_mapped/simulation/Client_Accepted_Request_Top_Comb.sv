        SMIdle: begin
            next_state = SM_S1;
        end

        // --------------------------------------------
        SM_S1: begin
            next_state = SM_S2;
        end

        SM_S2: begin
            next_state = SM_S3;
        end

        SM_S3: begin
            next_state = SM_S4;
        end

        // --------------------------------------------
        SM_S4: begin
            next_state = SM_S4;
            if (rx_complete) begin
                next_state = SM_S5;
            end
        end

        // --------------------------------------------
        SM_S5: begin
            next_state = SM_S6;
        end

        SM_S6: begin
            next_state = SM_S7;
        end

        SM_S7: begin
            next_state = SM_S8;
        end

        // --------------------------------------------
        SM_S8: begin
            next_state = SM_S8;

            if (tx_complete) begin
                next_state = SM_S9;
            end
        end

        SM_S9: begin
            next_state = SM_S10;
        end

        SM_S10: begin
            next_state = SM_S11;
        end

        SM_S11: begin
            next_state = SM_S11;

            if (tx_complete) begin
                next_state = SM_S12;
            end
        end

        SM_S12: begin
            next_state = SMStop;
        end


