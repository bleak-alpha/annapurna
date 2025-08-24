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
@Table(name = "CUST_PERSON_ACC")
@Data
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CustomerPersonAcc {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "customer_id")
    private Integer customerId;
    
    @Column(name = "customer_number", unique = true, nullable = false)
    private String customerNumber;
    
    @Column(name = "name", nullable = false)
    private String name;
    
    @Column(name = "phone")
    private String phone;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
    
    @Column(name = "is_active")
    private Boolean isActive = true;
    
    @Column(name = "total_due", precision = 10, scale = 2)
    private BigDecimal totalDue = BigDecimal.ZERO;
}