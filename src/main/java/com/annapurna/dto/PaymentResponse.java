package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaymentResponse {
    private Integer paymentId;
    private Integer customerId;
    private String customerName;
    private BigDecimal amountPaid;
    private String paymentMode;
    private LocalDateTime paymentDate;
    private Integer linesUpdated;
}