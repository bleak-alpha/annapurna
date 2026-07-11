package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MenuItemResponse {
    private Integer itemId;
    private String itemCode;
    private Integer itemNumber;
    private String itemDescription;
    private BigDecimal cost;
}