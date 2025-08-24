package com.annapurna.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "FOO_COST_SHEET")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CostSheet {
    @Id
    @Column(name = "item_id")
    private Integer itemId;
    
    @OneToOne
    @MapsId
    @JoinColumn(name = "item_id")
    private FoodMst foodMst;
    
    @Column(name = "cost", nullable = false, precision = 10, scale = 2)
    private BigDecimal cost;
    
    @Column(name = "is_active")
    private Boolean isActive = true;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
}