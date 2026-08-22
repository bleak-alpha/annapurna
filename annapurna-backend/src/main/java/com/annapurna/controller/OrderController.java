package com.annapurna.controller;

import com.annapurna.constant.ApiConstant;
import com.annapurna.dto.*;
import com.annapurna.dto.Order.OrderRequest;
import com.annapurna.dto.Order.UpdateOrderRequest;
import com.annapurna.model.generic.GenericResponse;
import com.annapurna.service.OrderService;
import com.annapurna.service.OrderServicee;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

import static com.annapurna.enums.ResponseCode.INA_CANTEEN_CODE_99999;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {
    
    private final OrderService orderService;

    private final OrderServicee orderServicee;

    
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

    @PostMapping(ApiConstant.ADD_ORDER)
    public ResponseEntity<GenericResponse> addOrder(@RequestBody OrderRequest request){
        try {
            GenericResponse response= orderServicee.addOrder(request);
            return ResponseEntity.ok(response);
        } catch (Exception e){
          GenericResponse  response = (GenericResponse.builder()
                            .errorMessage(INA_CANTEEN_CODE_99999.getValue())
                            .errorCode(INA_CANTEEN_CODE_99999.getKey()).build());
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response);
        }
    }

    @PostMapping(ApiConstant.UPDATE_ORDER)
    public ResponseEntity<GenericResponse> updateOrder(@RequestBody UpdateOrderRequest request){
        try {
            GenericResponse response = orderServicee.updateOrder(request);
            return ResponseEntity.ok(response);
        } catch (Exception e){
            GenericResponse  response = (GenericResponse.builder()
                    .errorMessage(INA_CANTEEN_CODE_99999.getValue())
                    .errorCode(INA_CANTEEN_CODE_99999.getKey()).build());
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response);
        }
    }


}