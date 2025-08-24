package com.annapurna.dto;

import lombok.Data;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class MenuItemResponse {
    private Integer itemId;
    private String itemCode;
    private String itemDescription;
    private BigDecimal cost;
}