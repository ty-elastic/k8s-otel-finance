package com.example.recorder;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/**
 * Service layer is where all the business logic lies
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TradeRecorder {

    private final TradeRepo tradeRepo;
    private boolean pgStatEnabled = false;

    @Transactional
    public Trade recordTrade (Trade trade){
        if (!pgStatEnabled) {
            try {
                log.atInfo().log("enabling pg_stat_statements");
                tradeRepo.enablePGStatStatements();
            }
            catch (Exception e) {

            }
            pgStatEnabled = true;
        }

        Trade savedTrade = tradeRepo.save(trade);

        log.atInfo().log("trade committed for " + trade.customerId);
 
        return savedTrade;
    }
}
