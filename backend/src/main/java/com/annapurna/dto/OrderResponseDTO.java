package com.annapurna.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class OrderResponseDTO {
    private Long headerId;
    private Long customerId;
    private String customerName;
    private String whoGaveOrder;
    private LocalDateTime creationDate;
    private BigDecimal totalDue;
    private Boolean isPaid;
    private Boolean isDeferred;
    private List<OrderLineDTO> orderLines;
    
    // Constructors, getters, setters
    public OrderResponseDTO() {}
    
    public Long getHeaderId() { return headerId; }
    public void setHeaderId(Long headerId) { this.headerId = headerId; }
    
    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }
    
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    
    public String getWhoGaveOrder() { return whoGaveOrder; }
    public void setWhoGaveOrder(String whoGaveOrder) { this.whoGaveOrder = whoGaveOrder; }
    
    public LocalDateTime getCreationDate() { return creationDate; }
    public void setCreationDate(LocalDateTime creationDate) { this.creationDate = creationDate; }
    
    public BigDecimal getTotalDue() { return totalDue; }
    public void setTotalDue(BigDecimal totalDue) { this.totalDue = totalDue; }
    
    public Boolean getIsPaid() { return isPaid; }
    public void setIsPaid(Boolean isPaid) { this.isPaid = isPaid; }
    
    public Boolean getIsDeferred() { return isDeferred; }
    public void setIsDeferred(Boolean isDeferred) { this.isDeferred = isDeferred; }
    
    public List<OrderLineDTO> getOrderLines() { return orderLines; }
    public void setOrderLines(List<OrderLineDTO> orderLines) { this.orderLines = orderLines; }
    
    public static class OrderLineDTO {
        private Long lineId;
        private String itemCode;
        private String itemDescription;
        private Integer quantity;
        private BigDecimal costPerItem;
        private BigDecimal totalCost;
        private Boolean isServed;
        private LocalDateTime servedAt;
        private String servedBy;
        
        // Getters and setters
        public Long getLineId() { return lineId; }
        public void setLineId(Long lineId) { this.lineId = lineId; }
        
        public String getItemCode() { return itemCode; }
        public void setItemCode(String itemCode) { this.itemCode = itemCode; }
        
        public String getItemDescription() { return itemDescription; }
        public void setItemDescription(String itemDescription) { this.itemDescription = itemDescription; }
        
        public Integer getQuantity() { return quantity; }
        public void setQuantity(Integer quantity) { this.quantity = quantity; }
        
        public BigDecimal getCostPerItem() { return costPerItem; }
        public void setCostPerItem(BigDecimal costPerItem) { this.costPerItem = costPerItem; }
        
        public BigDecimal getTotalCost() { return totalCost; }
        public void setTotalCost(BigDecimal totalCost) { this.totalCost = totalCost; }
        
        public Boolean getIsServed() { return isServed; }
        public void setIsServed(Boolean isServed) { this.isServed = isServed; }
        
        public LocalDateTime getServedAt() { return servedAt; }
        public void setServedAt(LocalDateTime servedAt) { this.servedAt = servedAt; }
        
        public String getServedBy() { return servedBy; }
        public void setServedBy(String servedBy) { this.servedBy = servedBy; }
    }
}