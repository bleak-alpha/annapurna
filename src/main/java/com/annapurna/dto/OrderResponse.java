package com.annapurna.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponse {
    private Integer headerId;
    private Long orderNumber;
    private LocalDateTime creationDate;
    private String whoGaveOrder;
    private String customerName;
    private Integer customerId;
    private Boolean isPaidFull;
    private Boolean isDeferred;
    private BigDecimal totalDue;
    private List<OrderLineResponse> lines;
}