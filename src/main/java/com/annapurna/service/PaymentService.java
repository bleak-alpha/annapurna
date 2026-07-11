package com.annapurna.service;

import com.annapurna.dto.*;
import com.annapurna.exception.CustomerNotFoundException;
import com.annapurna.model.*;
import com.annapurna.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class PaymentService {
    
    private final CustomerPaymentHistRepository paymentHistRepository;
    private final CustomerOrderHistRepository orderHistRepository;
    private final CustomerPersonAccRepository customerRepository;
    private final OrderLineRepository orderLineRepository;
    
    public PaymentResponse recordPayment(PaymentRequest request) {
        CustomerPersonAcc customer = customerRepository.findById(request.getCustomerId())
            .orElseThrow(() -> new CustomerNotFoundException("Customer not found: " + request.getCustomerId()));
        
        CustomerPaymentHist payment = new CustomerPaymentHist();
        payment.setCustomer(customer);
        payment.setAmountPaid(request.getAmountPaid());
        payment.setPaymentMode(request.getPaymentMode());
        payment.setPaymentDate(request.getPaymentDate() != null ? request.getPaymentDate() : LocalDateTime.now());
        
        // Save payment (triggers will handle updating customer order history)
        payment = paymentHistRepository.save(payment);
        
        // Count how many lines were updated
        List<CustomerOrderHist> updatedHistory = orderHistRepository.findByPaymentId(payment.getPaymentId());
        
        return new PaymentResponse(
            payment.getPaymentId(),
            customer.getCustomerId(),
            customer.getName(),
            payment.getAmountPaid(),
            payment.getPaymentMode(),
            payment.getPaymentDate(),
            updatedHistory.size()
        );
    }
    
    @Transactional(readOnly = true)
    public List<CustomerOrderHist> getUnpaidOrders(Integer customerId) {
        return orderHistRepository.findUnpaidOrdersByCustomer(customerId);
    }
    
    @Transactional(readOnly = true)
    public List<CustomerPaymentHist> getPaymentHistory(Integer customerId) {
        return paymentHistRepository.findByCustomerId(customerId);
    }
}
