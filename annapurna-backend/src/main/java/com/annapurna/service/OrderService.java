package com.annapurna.service;

import com.annapurna.dto.CreateOrderRequest;
import com.annapurna.dto.OrderItemRequest;
import com.annapurna.dto.PendingOrderResponse;
import com.annapurna.exception.MenuItemNotFoundException;
import com.annapurna.exception.CustomerNotFoundException;
import com.annapurna.model.*;
import com.annapurna.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

@Service
@RequiredArgsConstructor
@Transactional
public class OrderService {
    
    private final OrderHeaderRepository orderHeaderRepository;
    private final OrderLineRepository orderLineRepository;
    private final FoodMstRepository foodMstRepository;
    private final CostSheetRepository costSheetRepository;
    private final CustomerPersonAccRepository customerRepository;
    
    public Integer createOrder(CreateOrderRequest request) {
        OrderHeader orderHeader = new OrderHeader();
        orderHeader.setWhoGaveOrder(request.getWhoGaveOrder());
        orderHeader.setIsDeferred(request.getIsDeferred());
        
        if (request.getCustomerId() != null) {
            CustomerPersonAcc customer = customerRepository.findById(request.getCustomerId())
                .orElseThrow(() -> new CustomerNotFoundException("Customer not found"));
            orderHeader.setCustomer(customer);
            orderHeader.setIsKnownCustomer(true);
        }
        
        orderHeader = orderHeaderRepository.save(orderHeader);
        
        List<OrderLine> orderLines = new ArrayList<>();
        BigDecimal totalOrderAmount = BigDecimal.ZERO;
        
        for (OrderItemRequest itemRequest : request.getItems()) {
            FoodMst foodItem = foodMstRepository.findByItemCodeAndInUseTrue(itemRequest.getItemCode())
                .orElseThrow(() -> new MenuItemNotFoundException("Food item not found: " + itemRequest.getItemCode()));
            
            CostSheet costSheet = costSheetRepository.findByItemIdAndIsActiveTrue(foodItem.getItemId())
                .orElseThrow(() -> new MenuItemNotFoundException("Cost not found for item: " + itemRequest.getItemCode()));
            
            OrderLine orderLine = new OrderLine();
            orderLine.setOrderHeader(orderHeader);
            orderLine.setFoodMst(foodItem);
            orderLine.setQuantity(itemRequest.getQuantity());
            orderLine.setCostPerItem(costSheet.getCost());
            orderLine.calculateTotalCost();
            
            orderLines.add(orderLine);
            totalOrderAmount = totalOrderAmount.add(orderLine.getTotalCost());
        }
        
        orderLineRepository.saveAll(orderLines);
        
        orderHeader.setTotalDue(totalOrderAmount);
        orderHeaderRepository.save(orderHeader);
        
        return orderHeader.getHeaderId();
    }
    
    @Transactional(readOnly = true)
    public List<PendingOrderResponse> getUnservedOrders() {
        return orderLineRepository.getUnservedOrders();
    }
    
    public void markItemsAsServed(List<Integer> lineIds, String servedBy) {
        orderLineRepository.markItemsAsServed(lineIds, LocalDateTime.now(), servedBy);
    }
}