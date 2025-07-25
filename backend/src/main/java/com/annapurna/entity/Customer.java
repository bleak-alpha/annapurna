package com.annapurna.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "cust_person_acc")
public class Customer {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "customer_id")
    private Long customerId;
    
    @Column(name = "customer_number", unique = true, nullable = false)
    private String customerNumber;
    
    @Column(nullable = false)
    private String name;
    
    private String phone;
    
    @Column(name = "creation_date")
    private LocalDateTime creationDate;
    
    @Column(name = "is_active")
    private Boolean isActive = true;
    
    @Column(name = "total_due", precision = 10, scale = 2)
    private BigDecimal totalDue = BigDecimal.ZERO;
    
    @OneToMany(mappedBy = "customer", fetch = FetchType.LAZY)
    private List<Order> orders;
    
    @PrePersist
    protected void onCreate() {
        creationDate = LocalDateTime.now();
    }
    
    // Constructors
    public Customer() {}
    
    public Customer(String customerNumber, String name, String phone) {
        this.customerNumber = customerNumber;
        this.name = name;
        this.phone = phone;
    }
    
    // Getters and Setters
    public Long getCustomerId() { return customerId; }
    public void setCustomerId(Long customerId) { this.customerId = customerId; }
    
    public String getCustomerNumber() { return customerNumber; }
    public void setCustomerNumber(String customerNumber) { this.customerNumber = customerNumber; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    
    public LocalDateTime getCreationDate() { return creationDate; }
    public void setCreationDate(LocalDateTime creationDate) { this.creationDate = creationDate; }
    
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    
    public BigDecimal getTotalDue() { return totalDue; }
    public void setTotalDue(BigDecimal totalDue) { this.totalDue = totalDue; }
    
    public List<Order> getOrders() { return orders; }
    public void setOrders(List<Order> orders) { this.orders = orders; }
}