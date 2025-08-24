package com.annapurna.repository;

import com.annapurna.model.OrderLine;
import com.annapurna.dto.PendingOrderResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderLineRepository extends JpaRepository<OrderLine, Integer> {
    
    @Query("""
        SELECT new com.annapurna.dto.PendingOrderResponse(
            oh.headerId, oh.creationDate, 
            COALESCE(c.name, 'Walk-in Customer'),
            fm.itemCode, fm.itemDescription, ol.quantity, ol.lineId,
            ol.totalCost, oh.isPaid
        )
        FROM OrderLine ol
        JOIN ol.orderHeader oh
        JOIN ol.foodMst fm
        LEFT JOIN oh.customer c
        WHERE ol.isServed = false
        ORDER BY oh.creationDate ASC
    """)
    List<PendingOrderResponse> getUnservedOrders();
    
    @Modifying
    @Query("""
        UPDATE OrderLine ol 
        SET ol.isServed = true, ol.servedAt = :servedAt, ol.servedBy = :servedBy
        WHERE ol.lineId IN :lineIds AND ol.isServed = false
    """)
    void markItemsAsServed(@Param("lineIds") List<Integer> lineIds, 
                          @Param("servedAt") LocalDateTime servedAt, 
                          @Param("servedBy") String servedBy);
    
    @Query("SELECT COUNT(*) FROM OrderLine ol WHERE ol.isServed = false")
    Long countPendingOrders();
}