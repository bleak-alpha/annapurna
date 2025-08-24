package com.annapurna.repository;

import com.annapurna.model.OrderHeader;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.math.BigDecimal;

@Repository
public interface OrderHeaderRepository extends JpaRepository<OrderHeader, Integer> {
    
    @Query("SELECT COUNT(*) FROM OrderHeader oh WHERE DATE(oh.creationDate) = :date")
    Long countTodayOrders(@Param("date") LocalDate date);
    
    @Query("SELECT COALESCE(SUM(oh.totalDue), 0) FROM OrderHeader oh WHERE DATE(oh.creationDate) = :date AND oh.isPaid = true")
    BigDecimal getTodayRevenue(@Param("date") LocalDate date);
    
    @Query("SELECT COUNT(*) FROM OrderHeader oh WHERE oh.isPaid = false")
    Long countUnpaidOrders();
    
    @Query("SELECT COALESCE(SUM(oh.totalDue), 0) FROM OrderHeader oh WHERE oh.isPaid = false AND oh.customer IS NOT NULL")
    BigDecimal getTotalCustomerDues();
}