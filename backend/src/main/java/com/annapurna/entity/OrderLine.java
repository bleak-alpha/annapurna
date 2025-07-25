package com.annapurna.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "om_order_lines")
public class OrderLine {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "line_id")
    private Long lineId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "header_id", nullable = false)
    private Order order;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", nullable = false)
    private MenuItem menuItem;
    
    @Column(nullable = false)
    private Integer quantity;
    
    @Column(name = "cost_per_item", nullable = false, precision = 10, scale = 2)
    private BigDecimal costPerItem;
    
    @Column(name = "total_cost", precision = 10, scale = 2)
    private BigDecimal totalCost;
    
    @Column(name = "is_served")
    private Boolean isServed = false;
    
    @Column(name = "served_at")
    private LocalDateTime servedAt;
    
    @Column(name = "served_by")
    private String servedBy;
    
    @PrePersist
    protected void onCreate() {
        creationDate = LocalDateTime.now();
        if (totalCost == null && quantity != null && costPerItem != null) {
            totalCost = costPerItem.multiply(BigDecimal.valueOf(quantity));
        }
    }
    
    // Constructors, getters, setters
    public OrderLine() {}
    
    public OrderLine(Order order, MenuItem menuItem, Integer quantity, BigDecimal costPerItem) {
        this.order = order;
        this.menuItem = menuItem;
        this.quantity = quantity;
        this.costPerItem = costPerItem;
        this.totalCost = costPerItem.multiply(BigDecimal.valueOf(quantity));
    }
    
    // Getters and Setters
    public Long getLineId() { return lineId; }
    public void setLineId(Long lineId) { this.lineId = lineId; }
    
    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }
    
    public LocalDateTime getCreationDate() { return creationDate; }
    public void setCreationDate(LocalDateTime creationDate) { this.creationDate = creationDate; }
    
    public MenuItem getMenuItem() { return menuItem; }
    public void setMenuItem(MenuItem menuItem) { this.menuItem = menuItem; }
    
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