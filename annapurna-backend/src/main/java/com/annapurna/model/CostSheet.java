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
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "cost_id")
    private Integer costId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", nullable = false)
    private FoodMst foodMst;
    
    @Column(name = "cost", nullable = false, precision = 10, scale = 2)
    private BigDecimal cost;
    
    @Column(name = "is_active")
    private Boolean isActive = true;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
    
    @Column(name = "inactive_date")
    private LocalDateTime inactiveDate;
}
