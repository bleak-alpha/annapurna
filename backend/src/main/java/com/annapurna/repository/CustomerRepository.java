package com.annapurna.repository;

import com.annapurna.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    
    // Find customer by phone
    Optional<Customer> findByPhone(String phone);
    
    // Find customer by customer number
    Optional<Customer> findByCustomerNumber(String customerNumber);
    
    // Find customers with due amounts
    @Query("SELECT c FROM Customer c WHERE c.totalDue > 0 AND c.isActive = true")
    List<Customer> findCustomersWithDues();
    
    // Get customer summary using stored procedure
    @Query(value = "SELECT * FROM get_customer_summary(:customerId)", nativeQuery = true)
    Object[] getCustomerSummaryRaw(@Param("customerId") Long customerId);
    
    // Process customer payment using stored procedure
    @Procedure(procedureName = "process_customer_payment")
    Long processCustomerPayment(@Param("p_customer_id") Long customerId,
                               @Param("p_payment_amount") BigDecimal paymentAmount,
                               @Param("p_order_ids") Long[] orderIds);
}