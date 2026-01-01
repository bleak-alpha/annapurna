package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PendingOrderResponse {
    private Integer headerId;
    private Long orderNumber;
    private LocalDateTime orderTime;
    private String customerName;
    private String itemCode;
    private Integer itemNumber;
    private String itemName;
    private Integer lineNumber;
    private Integer quantity;
    private Integer lineId;
    private BigDecimal totalCost;
    private Boolean isPaidFull;
    private Boolean isDeferred;
}