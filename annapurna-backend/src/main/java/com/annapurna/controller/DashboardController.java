package com.annapurna.controller;

import com.annapurna.dto.DashboardStatsResponse;
import com.annapurna.dto.NewOrderRequest;
import com.annapurna.dto.OrderDashResponse;
import com.annapurna.service.DashboardService;
//import com.annapurna.service.OrderDashboardService;
import com.fasterxml.jackson.core.JsonProcessingException;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;


import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@Controller
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {
    
    private final DashboardService dashboardService;
//
//    @Autowired
//    private OrderDashboardService orderDashboardService;
//
    @GetMapping("/stats")
    public ResponseEntity<DashboardStatsResponse> getDashboardStats() {
        return ResponseEntity.ok(dashboardService.getDashboardStats());
    }

//    @GetMapping("/dashboardData")
//    public ResponseEntity<List<OrderDashResponse>> getallorderData() {
//
//        List<OrderDashResponse> response =
//                orderDashboardService.getAllDashboardData();
//
//        return ResponseEntity.ok(response);
//    }
//
//    @PostMapping("/updateOrder")
//    public ResponseEntity<OrderDashResponse> updateOrder(
//            @RequestBody NewOrderRequest request) throws JsonProcessingException {
//
//        return ResponseEntity.ok(orderDashboardService.updateOrder(request));
//    }




}