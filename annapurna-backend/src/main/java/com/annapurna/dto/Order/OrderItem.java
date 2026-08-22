package com.annapurna.dto.Order;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;


@Data
@AllArgsConstructor
@NoArgsConstructor
public class OrderItem {


    private String itemDescription;
    private Integer qty;
    private Boolean served;
    private BigDecimal cost;

}