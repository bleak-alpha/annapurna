package com.annapurna.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "om_order_headers")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "header_id")
    private Long headerId;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate;
    
    @Column(name = "who_gave_order")
    private String whoGaveOrder;
    
    @Column(name = "when_ordered")
    private LocalDateTime whenOrdered;
    
    @Column(name = "is_paid")
    private Boolean isPaid = false;
    
    @Column(name = "is_deferred")
    private Boolean isDeferred = false;
    
    @Column(name = "is_known_customer")
    private Boolean isKnownCustomer = false;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer;
    
    @Column(name = "total_due", precision = 10, scale = 2)
    private BigDecimal totalDue = BigDecimal.ZERO;
    
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderLine> orderLines;
    
    @PrePersist
    protected void onCreate() {
        creationDate = LocalDateTime.now();
        whenOrdered = LocalDateTime.now();
    }
    
    // Constructors, getters, setters
    public Order() {}
    
    public Order(Customer customer, String whoGaveOrder, Boolean isDeferred) {
        this.customer = customer;
        this.whoGaveOrder = whoGaveOrder;
        this.isDeferred = isDeferred;
        this.isKnownCustomer = (customer != null);
    }
    
    // Getters and Setters
    public Long getHeaderId() { return headerId; }
    public void setHeaderId(Long headerId) { this.headerId = headerId; }
    
    public LocalDateTime getCreationDate() { return creationDate; }
    public void setCreationDate(LocalDateTime creationDate) { this.creationDate = creationDate; }
    
    public String getWhoGaveOrder() { return whoGaveOrder; }
    public void setWhoGaveOrder(String whoGaveOrder) { this.whoGaveOrder = whoGaveOrder; }
    
    public LocalDateTime getWhenOrdered() { return whenOrdered; }
    public void setWhenOrdered(LocalDateTime whenOrdered) { this.whenOrdered = whenOrdered; }
    
    public Boolean getIsPaid() { return isPaid; }
    public void setIsPaid(Boolean isPaid) { this.isPaid = isPaid; }
    
    public Boolean getIsDeferred() { return isDeferred; }
    public void setIsDeferred(Boolean isDeferred) { this.isDeferred = isDeferred; }
    
    public Boolean getIsKnownCustomer() { return isKnownCustomer; }
    public void setIsKnownCustomer(Boolean isKnownCustomer) { this.isKnownCustomer = isKnownCustomer; }
    
    public Customer getCustomer() { return customer; }
    public void setCustomer(Customer customer) { this.customer = customer; }
    
    public BigDecimal getTotalDue() { return totalDue; }
    public void setTotalDue(BigDecimal totalDue) { this.totalDue = totalDue; }
    
    public List<OrderLine> getOrderLines() { return orderLines; }
    public void setOrderLines(List<OrderLine> orderLines) { this.orderLines = orderLines; }
}