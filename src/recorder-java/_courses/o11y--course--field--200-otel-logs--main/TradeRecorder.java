package com.example.recorder;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.annotation.*;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

/**
 * Service layer is where all the business logic lies
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TradeRecorder {

    private final TradeRepo tradeRepo;

    @Transactional
    public Trade recordTrade (Trade trade){
        Trade savedTrade = tradeRepo.save(trade);

        TransactionStatus status = TransactionAspectSupport.currentTransactionStatus();
        log.atInfo().addKeyValue(Main.ATTRIBUTE_PREFIX + ".hash_code", status.hashCode()).log("trade committed for " + trade.customerId);
 
        return savedTrade;
    }
}
