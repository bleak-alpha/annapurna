package com.annapurna.dto.Menu;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateNewMenuRequest {

    private String itemCode;
    private Integer itemNumber;
    private String itemDescription;
    private BigDecimal cost;
    private Boolean inUse;
    private Boolean isActive;


}
