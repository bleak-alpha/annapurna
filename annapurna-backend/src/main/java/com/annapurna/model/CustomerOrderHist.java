package com.annapurna.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "CUST_ORDER_HIST")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerOrderHist {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "hist_id")
    private Integer histId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id", nullable = false)
    private CustomerPersonAcc customer;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "line_id", nullable = false)
    private OrderLine orderLine;
    
    @Column(name = "is_paid_now")
    private Boolean isPaidNow = false;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payment_id")
    private CustomerPaymentHist payment;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
}