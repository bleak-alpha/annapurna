package com.annapurna.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "OM_ORDER_HEADERS")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderHeader {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "order_header_seq")
    @SequenceGenerator(name = "order_header_seq", sequenceName = "om_order_headers_seq", allocationSize = 1)
    @Column(name = "header_id")
    private Integer headerId;
    
    @Column(name = "order_number", unique = true)
    private Long orderNumber;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate = LocalDateTime.now();
    
    @Column(name = "who_gave_order")
    private String whoGaveOrder;
    
    @Column(name = "when_ordered")
    private LocalDateTime whenOrdered = LocalDateTime.now();
    
    @Column(name = "is_paid_full")
    private Boolean isPaidFull = false;
    
    @Column(name = "is_deferred")
    private Boolean isDeferred;
    
    @Column(name = "is_known_customer")
    private Boolean isKnownCustomer = false;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private CustomerPersonAcc customer;
    
    @Column(name = "total_due", precision = 10, scale = 2)
    private BigDecimal totalDue = BigDecimal.ZERO;
    
    @OneToMany(mappedBy = "orderHeader", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<OrderLine> orderLines = new ArrayList<>();
    
    // Helper method to add order line
    public void addOrderLine(OrderLine orderLine) {
        orderLines.add(orderLine);
        orderLine.setOrderHeader(this);
    }
}