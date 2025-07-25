package com.annapurna.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public class OrderRequestDTO {
    private Long customerId;
    
    @NotNull
    private String whoGaveOrder;
    
    private Boolean isDeferred = false;
    
    @NotEmpty
    private List<OrderItemDTO> items;
    
    // Constructors, getters, setters
    public OrderRequestDTO() {}
    
    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }
    
    public String getWhoGaveOrder() { return whoGaveOrder; }
    public void setWhoGaveOrder(String whoGaveOrder) { this.whoGaveOrder = whoGaveOrder; }
    
    public Boolean getIsDeferred() { return isDeferred; }
    public void setIsDeferred(Boolean isDeferred) { this.isDeferred = isDeferred; }
    
    public List<OrderItemDTO> getItems() { return items; }
    public void setItems(List<OrderItemDTO> items) { this.items = items; }
    
    public static class OrderItemDTO {
        @NotNull
        private String itemCode;
        
        @NotNull
        private Integer quantity;
        
        public OrderItemDTO() {}
        
        public String getItemCode() { return itemCode; }
        public void setItemCode(String itemCode) { this.itemCode = itemCode; }
        
        public Integer getQuantity() { return quantity; }
        public void setQuantity(Integer quantity) { this.quantity = quantity; }
    }
}