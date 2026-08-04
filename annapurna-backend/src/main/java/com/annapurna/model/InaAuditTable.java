package com.annapurna.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "INA_CANTEEN_AUDIT")
public class InaAuditTable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID")
    private Long id;

    @Column(name = "CUSTOMER_NAME")
    private String custmerName;

    @Column(name = "CUSTOMER_ID")
    private String customerId;

    @Column(name = "TABLE_NO")
    private String tableNo;

    @Column(name = "ORDER_DETAILS")
    private String orderDetails;

    @Column(name = "TOTAL_PAYMENT")
    private double totalPayment;

    @Column(name = "PAYMENT_METHOD")
    private String paymentMethod;

    @Column(name = "DUE_AMOUNT")
    private String dueAmount;

    @Column(name = "ORDER_STATUS")
    private String orderStatus;

    @Column(name = "CREATED_DATE")
    private LocalDateTime createdDate;
}