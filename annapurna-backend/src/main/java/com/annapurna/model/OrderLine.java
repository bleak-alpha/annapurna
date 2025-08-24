package com.annapurna.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "OM_ORDER_LINES")
@Data
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderLine {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "line_id")
    private Integer lineId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "header_id", nullable = false)
    private OrderHeader orderHeader;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", nullable = false)
    private FoodMst foodMst;
    
    @Column(name = "quantity", nullable = false)
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
    @PreUpdate
    public void calculateTotalCost() {
        if (quantity != null && costPerItem != null) {
            this.totalCost = costPerItem.multiply(BigDecimal.valueOf(quantity));
        }
    }
}