package com.annapurna.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemRequest {
    private String itemCode;
    private Integer itemNumber;
    
    @NotNull(message = "Quantity is required")
    @Min(value = 1, message = "Quantity must be at least 1")
    private Integer quantity;
    
    @AssertTrue(message = "Either itemCode or itemNumber must be provided")
    private boolean isItemIdentifierValid() {
        return itemCode != null || itemNumber != null;
    }
}