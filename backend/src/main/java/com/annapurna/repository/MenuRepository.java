package com.annapurna.repository;

import com.annapurna.entity.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MenuRepository extends JpaRepository<MenuItem, Long> {
    
    // Get active menu with prices using the view
    @Query(value = "SELECT item_id, item_code, item_description, cost, creation_date FROM v_active_menu", 
           nativeQuery = true)
    List<Object[]> getActiveMenuRaw();
    
    // Find menu item by code
    @Query("SELECT m FROM MenuItem m WHERE m.itemCode = :itemCode AND m.inUse = true")
    Optional<MenuItem> findByItemCode(@Param("itemCode") String itemCode);
    
    // Find active menu items
    @Query("SELECT m FROM MenuItem m WHERE m.inUse = true ORDER BY m.itemCode")
    List<MenuItem> findActiveMenuItems();
}