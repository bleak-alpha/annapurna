package com.annapurna.dto.WS;

import com.annapurna.dto.Order.OrderItem;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WsOrderRequest {

    private Long id;

    private String srNo;

    private String customerName;

    private String customerId;

    private String tableNo;

    private List<OrderItem> orders;

    private double totalPayment;

    private String paymentMethod;

    private String previouesDue;

    private String status;
}
