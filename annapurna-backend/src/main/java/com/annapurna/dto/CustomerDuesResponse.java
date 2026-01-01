package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDuesResponse {
    private Integer customerId;
    private String customerNumber;
    private String customerName;
    private String phone;
    private BigDecimal totalDue;
    private List<UnpaidOrderLineDto> unpaidLines;
}