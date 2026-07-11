package com.annapurna.controller;

import com.annapurna.dto.PaymentRequest;
import com.annapurna.dto.PaymentResponse;
import com.annapurna.model.CustomerOrderHist;
import com.annapurna.model.CustomerPaymentHist;
import com.annapurna.service.PaymentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {
    
    private final PaymentService paymentService;
    
    @PostMapping("/pay")
    public ResponseEntity<PaymentResponse> recordPayment(@Valid @RequestBody PaymentRequest request) {
        PaymentResponse response = paymentService.recordPayment(request);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/unpaid/{customerId}")
    public ResponseEntity<List<CustomerOrderHist>> getUnpaidOrders(@PathVariable Integer customerId) {
        return ResponseEntity.ok(paymentService.getUnpaidOrders(customerId));
    }
    
    @GetMapping("/history/{customerId}")
    public ResponseEntity<List<CustomerPaymentHist>> getPaymentHistory(@PathVariable Integer customerId) {
        return ResponseEntity.ok(paymentService.getPaymentHistory(customerId));
    }
}