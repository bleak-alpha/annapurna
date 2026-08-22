package com.annapurna.dto;

import com.annapurna.dto.Order.OrderItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NewOrderRequest {

    private Long id;

    private String custmerName;

    private String customerId;

    private String tableNo;

    private List<OrderItem> orders;

    private double totalPayment;

    private String paymentMethod;

    private String dueAmount;

    private String status;

}