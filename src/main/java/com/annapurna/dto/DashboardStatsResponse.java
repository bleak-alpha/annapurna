package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DashboardStatsResponse {
    private Long todayOrders;
    private BigDecimal todayRevenue;
    private Long pendingOrders;
    private Long unpaidOrders;
    private BigDecimal totalCustomerDues;
}