package com.annapurna.repository;

import com.annapurna.entity.OrderLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface OrderLineRepository extends JpaRepository<OrderLine, Long> {
    
    // Use stored procedure to mark items as served
    @Procedure(procedureName = "mark_items_served")
    Boolean markItemsServed(@Param("p_line_ids") Long[] lineIds,
                           @Param("p_served_by") String servedBy);
    
    // Find unserved items
    @Query("SELECT ol FROM OrderLine ol WHERE ol.isServed = false ORDER BY ol.creationDate ASC")
    List<OrderLine> findUnservedItems();
    
    // Find unserved items by order
    @Query("SELECT ol FROM OrderLine ol WHERE ol.order.headerId = :headerId AND ol.isServed = false")
    List<OrderLine> findUnservedItemsByOrder(@Param("headerId") Long headerId);
}