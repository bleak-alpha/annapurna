package com.annapurna.dto.Order;

import lombok.Data;

import java.util.HashMap;
import java.util.List;


@Data
public class OrderRequest {

    private String customerName;
    private String customerId;
    private String eatMode;
    private List<OrderDetails> orderDetails;
    private int totalPayment;
    private int paidAmount;
    private int remainingAmount;
    private String paymentMode;
    private String orderStatus;
}
