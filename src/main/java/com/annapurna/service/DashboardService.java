package com.annapurna.service;

import com.annapurna.dto.DashboardStatsResponse;
import com.annapurna.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DashboardService {
    
    private final OrderHeaderRepository orderHeaderRepository;
    private final OrderLineRepository orderLineRepository;
    
    public DashboardStatsResponse getDashboardStats() {
        LocalDate today = LocalDate.now();
        
        return new DashboardStatsResponse(
            orderHeaderRepository.countTodayOrders(today),
            orderHeaderRepository.getTodayRevenue(today),
            orderLineRepository.countPendingOrders(),
            orderHeaderRepository.countUnpaidOrders(),
            orderHeaderRepository.getTotalCustomerDues()
        );
    }
}