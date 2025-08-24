package com.annapurna.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import java.util.List;

@Data
@Getter
@Setter
public class CreateOrderRequest {
    private Integer customerId;
    
    @NotNull(message = "Staff name is required")
    private String whoGaveOrder;
    
    private Boolean isDeferred = false;
    
    @NotEmpty(message = "Order must contain at least one item")
    @Valid
    private List<OrderItemRequest> items;
}