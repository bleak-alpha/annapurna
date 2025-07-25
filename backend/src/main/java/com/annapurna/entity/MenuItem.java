package com.annapurna.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "foo_food_mst")
public class MenuItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "item_id")
    private Long itemId;
    
    @Column(name = "item_code", unique = true, nullable = false)
    private String itemCode;
    
    @Column(name = "item_description", nullable = false)
    private String itemDescription;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate;
    
    @Column(name = "in_use")
    private Boolean inUse = true;
    
    // Cost from FOO_COST_SHEET (via view)
    @Transient
    private BigDecimal cost;
    
    @PrePersist
    protected void onCreate() {
        creationDate = LocalDateTime.now();
    }
    
    // Constructors
    public MenuItem() {}
    
    public MenuItem(String itemCode, String itemDescription) {
        this.itemCode = itemCode;
        this.itemDescription = itemDescription;
    }
    
    // Getters and Setters
    public Long getItemId() { return itemId; }
    public void setItemId(Long itemId) { this.itemId = itemId; }
    
    public String getItemCode() { return itemCode; }
    public void setItemCode(String itemCode) { this.itemCode = itemCode; }
    
    public String getItemDescription() { return itemDescription; }
    public void setItemDescription(String itemDescription) { this.itemDescription = itemDescription; }
    
    public LocalDateTime getCreationDate() { return creationDate; }
    public void setCreationDate(LocalDateTime creationDate) { this.creationDate = creationDate; }
    
    public Boolean getInUse() { return inUse; }
    public void setInUse(Boolean inUse) { this.inUse = inUse; }
    
    public BigDecimal getCost() { return cost; }
    public void setCost(BigDecimal cost) { this.cost = cost; }
}