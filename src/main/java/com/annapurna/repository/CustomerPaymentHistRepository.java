package com.annapurna.repository;

import com.annapurna.model.CustomerPaymentHist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface CustomerPaymentHistRepository extends JpaRepository<CustomerPaymentHist, Integer> {

    @Query("SELECT cph FROM CustomerPaymentHist cph WHERE cph.customer.customerId = :customerId ORDER BY cph.creationDate DESC")
    List<CustomerPaymentHist> findByCustomerId(@Param("customerId") Integer customerId);

    @Query("""
        SELECT cph
        FROM CustomerPaymentHist cph
        JOIN FETCH cph.customer
        WHERE cph.paymentDate >= :startDate
        AND cph.paymentDate < :endDate
        """)
    List<CustomerPaymentHist> findPaymentsBetweenDates(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);

}