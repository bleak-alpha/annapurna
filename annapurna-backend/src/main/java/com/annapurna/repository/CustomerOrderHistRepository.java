package com.annapurna.repository;

import com.annapurna.model.CustomerOrderHist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CustomerOrderHistRepository extends JpaRepository<CustomerOrderHist, Integer> {
    
    @Query("SELECT coh FROM CustomerOrderHist coh WHERE coh.customer.customerId = :customerId AND coh.isPaidNow = false")
    List<CustomerOrderHist> findUnpaidOrdersByCustomer(@Param("customerId") Integer customerId);
    
    @Query("SELECT coh FROM CustomerOrderHist coh WHERE coh.customer.customerId = :customerId ORDER BY coh.creationDate DESC")
    List<CustomerOrderHist> findAllOrderHistoryByCustomer(@Param("customerId") Integer customerId);
    
    @Query("SELECT coh FROM CustomerOrderHist coh WHERE coh.payment.paymentId = :paymentId")
    List<CustomerOrderHist> findByPaymentId(@Param("paymentId") Integer paymentId);
}