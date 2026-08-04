package com.annapurna.repository;

import com.annapurna.model.OrderHeader;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderHeaderRepository extends JpaRepository<OrderHeader, Integer> {
    
    Optional<OrderHeader> findByOrderNumber(Long orderNumber);
    
    @Query("SELECT COUNT(*) FROM OrderHeader oh WHERE DATE(oh.creationDate) = :date")
    Long countTodayOrders(@Param("date") LocalDate date);
    
    @Query("SELECT COALESCE(SUM(oh.totalDue), 0) FROM OrderHeader oh WHERE DATE(oh.creationDate) = :date AND oh.isPaidFull = true")
    BigDecimal getTodayRevenue(@Param("date") LocalDate date);
    
    @Query("SELECT COUNT(*) FROM OrderHeader oh WHERE oh.isPaidFull = false")
    Long countUnpaidOrders();
    
    @Query("SELECT COALESCE(SUM(oh.totalDue), 0) FROM OrderHeader oh WHERE oh.isPaidFull = false AND oh.customer IS NOT NULL")
    BigDecimal getTotalCustomerDues();
    
    @Query("SELECT oh FROM OrderHeader oh WHERE oh.customer.customerId = :customerId ORDER BY oh.creationDate DESC")
    List<OrderHeader> findByCustomerId(@Param("customerId") Integer customerId);
    
    @Query("SELECT oh FROM OrderHeader oh WHERE oh.isPaidFull = false AND oh.isDeferred = true ORDER BY oh.creationDate")
    List<OrderHeader> findDeferredOrders();


}
