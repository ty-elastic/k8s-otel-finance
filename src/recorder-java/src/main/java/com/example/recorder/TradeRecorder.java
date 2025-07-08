package com.example.recorder;

import com.example.recorder.TradeRepo;
import com.example.recorder.Trade;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.slf4j.MDC;
import org.springframework.stereotype.Service;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.annotation.*;
import org.springframework.transaction.*;
import org.springframework.transaction.interceptor.TransactionAspectSupport;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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
        log.atInfo().addKeyValue("hash_code", status.hashCode()).log("trade committed for " + trade.customerId);
 
        return savedTrade;
    }
}
