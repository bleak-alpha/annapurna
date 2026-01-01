package com.annapurna.controller;

import com.annapurna.dto.*;
import com.annapurna.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {
    
    private final OrderService orderService;
    
    @PostMapping
    public ResponseEntity<Map<String, Integer>> createOrder(@Valid @RequestBody CreateOrderRequest request) {
        Integer orderId = orderService.createOrder(request);
        return ResponseEntity.ok(Map.of("orderId", orderId));
    }
    
    @GetMapping("/pending")
    public ResponseEntity<List<PendingOrderResponse>> getPendingOrders() {
        return ResponseEntity.ok(orderService.getUnservedOrders());
    }
    
    @PostMapping("/serve")
    public ResponseEntity<Void> markItemsServed(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Integer> lineIds = (List<Integer>) request.get("lineIds");
        String servedBy = (String) request.get("servedBy");
        
        orderService.markItemsAsServed(lineIds, servedBy);
        return ResponseEntity.ok().build();
    }
    
    @GetMapping("/number/{orderNumber}")
    public ResponseEntity<OrderResponse> getOrderByNumber(@PathVariable Long orderNumber) {
        return ResponseEntity.ok(orderService.getOrderByNumber(orderNumber));
    }
    
    @GetMapping("/{orderId}")
    public ResponseEntity<OrderResponse> getOrderById(@PathVariable Integer orderId) {
        return ResponseEntity.ok(orderService.getOrderById(orderId));
    }
}