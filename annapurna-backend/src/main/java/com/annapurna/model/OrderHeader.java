package com.annapurna.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "OM_ORDER_HEADERS")
@Data
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderHeader {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "header_id")
    private Integer headerId;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
    
    @Column(name = "who_gave_order")
    private String whoGaveOrder;
    
    @Column(name = "when_ordered")
    private LocalDateTime whenOrdered = LocalDateTime.now();
    
    @Column(name = "is_paid")
    private Boolean isPaid = false;
    
    @Column(name = "is_deferred")
    private Boolean isDeferred = false;
    
    @Column(name = "is_known_customer")
    private Boolean isKnownCustomer = false;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private CustomerPersonAcc customer;
    
    @Column(name = "total_due", precision = 10, scale = 2)
    private BigDecimal totalDue = BigDecimal.ZERO;
    
    @OneToMany(mappedBy = "orderHeader", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderLine> orderLines;
}