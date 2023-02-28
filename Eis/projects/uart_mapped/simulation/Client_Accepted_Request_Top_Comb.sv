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

        SM_S4: begin
            next_state = SM_S4;
            if (rx_complete) begin
                next_state = SM_S5;
            end
        end

        // --------------------------------------------
        SM_S5: begin
            next_state = SMStop;
        end


