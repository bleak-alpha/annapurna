package com.annapurna.service;

import com.annapurna.dto.NewOrderRequest;
import com.annapurna.dto.Order.OrderItem;
import com.annapurna.dto.OrderDashResponse;
import com.annapurna.model.InaAuditTable;
import com.annapurna.repository.INACanteenAuditReporsitory;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.SneakyThrows;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class OrderDashboardService {

    @Autowired
    private INACanteenAuditReporsitory auditRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @SneakyThrows
    public List<OrderDashResponse> getAllDashboardData() {

        LocalDate today = LocalDate.now();

        LocalDateTime start = today.atStartOfDay();
        LocalDateTime end = today.atTime(LocalTime.MAX);

        System.out.println("Start : " + start);
        System.out.println("End   : " + end);

        List<InaAuditTable> auditList =
                auditRepository.findByCreatedDateBetween(start, end);

        return auditList.stream()
                .map(audit -> {
                    try {
                        return convertToResponse(audit);
                    } catch (JsonProcessingException e) {
                        throw new RuntimeException(e);
                    }
                })
                .collect(Collectors.toList());
    }

    private OrderDashResponse convertToResponse(InaAuditTable audit)
            throws JsonProcessingException {

        List<OrderItem> orders = objectMapper.readValue(
                audit.getOrderDetails(),
                new TypeReference<List<OrderItem>>() {}
        );

        return OrderDashResponse.builder()
                .id(audit.getId())
                .custmerName(audit.getCustmerName())
                .customerId(audit.getCustomerId())
                .tableNo(audit.getTableNo())
                .orders(orders)
                .totalPayment(audit.getTotalPayment())
                .paymentMethod(audit.getPaymentMethod())
                .dueAmount(audit.getDueAmount())
                .orderStatus(audit.getOrderStatus())
                .build();
    }

    public OrderDashResponse updateOrder(NewOrderRequest request)
            throws JsonProcessingException {

        System.out.println("Order Object : " + request);

        // Uncomment this if you're updating an existing order
        /*
        InaAuditTable order = auditRepository.findById(request.getId())
                .orElseThrow(() -> new RuntimeException("Order not found"));
        */

        // For now creating a new order
        InaAuditTable order = new InaAuditTable();

        order.setCustmerName(request.getCustmerName());
        order.setCustomerId(request.getCustomerId());
        order.setTableNo(request.getTableNo());

        // Convert List<OrderItem> -> JSON String
        order.setOrderDetails(
                objectMapper.writeValueAsString(request.getOrders())
        );

        order.setTotalPayment(request.getTotalPayment());
        order.setPaymentMethod(request.getPaymentMethod());
        order.setDueAmount(request.getDueAmount());
        order.setOrderStatus(request.getStatus());
        order.setCreatedDate(LocalDateTime.now());

        InaAuditTable saved = auditRepository.save(order);

        // Convert JSON String -> List<OrderItem>
        return convertToResponse(saved);
    }
}