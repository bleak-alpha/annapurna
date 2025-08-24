package com.annapurna.dto;

import lombok.Data;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
public class PendingOrderResponse {
    private Integer headerId;
    private LocalDateTime orderTime;
    private String customerName;
    private String itemCode;
    private String itemName;
    private Integer quantity;
    private Integer lineId;
    private BigDecimal totalCost;
    private Boolean isPaid;
}