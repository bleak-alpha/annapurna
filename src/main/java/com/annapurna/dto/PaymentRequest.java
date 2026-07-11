package com.annapurna.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaymentRequest {
    @NotNull(message = "Customer ID is required")
    private Integer customerId;
    
    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0.01", message = "Amount must be greater than zero")
    private BigDecimal amountPaid;
    
    @NotNull(message = "Payment mode is required")
    @Pattern(regexp = "CASH|ONLINE", message = "Payment mode must be either CASH or ONLINE")
    private String paymentMode;
    
    private LocalDateTime paymentDate;
    private List<Integer> lineIds;
}
