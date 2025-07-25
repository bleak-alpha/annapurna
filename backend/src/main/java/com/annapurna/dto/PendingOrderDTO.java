package com.annapurna.dto;

import java.time.LocalDateTime;

public class PendingOrderDTO {
    private Long headerId;
    private LocalDateTime orderTime;
    private String customerName;
    private String itemCode;
    private String itemName;
    private Integer quantity;
    private Long lineId;
    
    // Constructor for SQL result mapping
    public PendingOrderDTO(Long headerId, LocalDateTime orderTime, String customerName, 
                          String itemCode, String itemName, Integer quantity, Long lineId) {
        this.headerId = headerId;
        this.orderTime = orderTime;
        this.customerName = customerName;
        this.itemCode = itemCode;
        this.itemName = itemName;
        this.quantity = quantity;
        this.lineId = lineId;
    }
    
    // Getters and setters
    public Long getHeaderId() { return headerId; }
    public void setHeaderId(Long headerId) { this.headerId = headerId; }
    
    public LocalDateTime getOrderTime() { return orderTime; }
    public void setOrderTime(LocalDateTime orderTime) { this.orderTime = orderTime; }
    
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    
    public String getItemCode() { return itemCode; }
    public void setItemCode(String itemCode) { this.itemCode = itemCode; }
    
    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }
    
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    
    public Long getLineId() { return lineId; }
    public void setLineId(Long lineId) { this.lineId = lineId; }
}