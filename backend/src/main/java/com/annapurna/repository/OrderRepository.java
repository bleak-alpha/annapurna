package com.annapurna.repository;

import com.annapurna.entity.Order;
import com.annapurna.dto.PendingOrderDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.query.Procedure;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    
    // Use stored procedure to create order with items
    @Procedure(procedureName = "create_order_with_items")
    Long createOrderWithItems(@Param("p_customer_id") Long customerId,
                             @Param("p_who_gave_order") String whoGaveOrder,
                             @Param("p_is_deferred") Boolean isDeferred,
                             @Param("p_order_items") String orderItemsJson);
    
    // Get unserved orders for display screen
    @Query(value = "SELECT * FROM get_unserved_orders()", nativeQuery = true)
    List<Object[]> getUnservedOrdersRaw();
    
    // Convert raw results to DTO
    default List<PendingOrderDTO> getUnservedOrders() {
        return getUnservedOrdersRaw().stream()
            .map(row -> new PendingOrderDTO(
                ((Number) row[0]).longValue(), // header_id
                (java.time.LocalDateTime) row[1], // order_time
                (String) row[2], // customer_name
                (String) row[3], // item_code
                (String) row[4], // item_name
                ((Number) row[5]).intValue(), // quantity
                ((Number) row[6]).longValue() // line_id
            ))
            .toList();
    }
    
    // Find unpaid orders by customer
    @Query("SELECT o FROM Order o WHERE o.customer.customerId = :customerId AND o.isPaid = false")
    List<Order> findUnpaidOrdersByCustomer(@Param("customerId") Long customerId);
    
    // Find orders by date range
    @Query("SELECT o FROM Order o WHERE o.creationDate BETWEEN :startDate AND :endDate")
    List<Order> findOrdersByDateRange(@Param("startDate") java.time.LocalDateTime startDate,
                                     @Param("endDate") java.time.LocalDateTime endDate);
}