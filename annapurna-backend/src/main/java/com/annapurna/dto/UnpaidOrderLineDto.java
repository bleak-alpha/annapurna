package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UnpaidOrderLineDto {
    private Integer lineId;
    private Long orderNumber;
    private LocalDateTime orderDate;
    private String itemDescription;
    private Integer quantity;
    private BigDecimal totalCost;
}
