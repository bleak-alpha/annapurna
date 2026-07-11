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
            oh.headerId, oh.orderNumber, oh.creationDate, 
            COALESCE(c.name, 'Walk-in Customer'),
            fm.itemCode, fm.itemNumber, fm.itemDescription, 
            ol.lineNumber, ol.quantity, ol.lineId,
            ol.totalCost, oh.isPaidFull, oh.isDeferred
        )
        FROM OrderLine ol
        JOIN ol.orderHeader oh
        JOIN ol.foodMst fm
        LEFT JOIN oh.customer c
        WHERE ol.isServed = false
        ORDER BY oh.creationDate ASC, ol.lineNumber ASC
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
    
    @Query("SELECT ol FROM OrderLine ol WHERE ol.orderHeader.headerId = :headerId ORDER BY ol.lineNumber")
    List<OrderLine> findByHeaderId(@Param("headerId") Integer headerId);
    
    @Query("SELECT COUNT(*) FROM OrderLine ol WHERE ol.orderHeader.headerId = :headerId AND ol.isPaid = false")
    Long countUnpaidLinesByHeaderId(@Param("headerId") Integer headerId);

    @Query("SELECT COALESCE(MAX(o.lineNumber), 0) FROM OrderLine o")
    Integer findMaxLineNumber();
}
