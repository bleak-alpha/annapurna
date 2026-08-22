package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderLineResponse {
    private Integer lineId;
    private Integer lineNumber;
    private String itemCode;
    private Integer itemNumber;
    private String itemDescription;
    private Integer quantity;
    private BigDecimal costPerItem;
    private BigDecimal totalCost;
    private Boolean isPaid;
    private Boolean isServed;
}