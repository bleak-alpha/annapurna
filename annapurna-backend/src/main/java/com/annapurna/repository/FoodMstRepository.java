package com.annapurna.repository;

import com.annapurna.model.FoodMst;
import com.annapurna.dto.MenuItemResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface FoodMstRepository extends JpaRepository<FoodMst, Integer> {
    
    Optional<FoodMst> findByItemCodeAndInUseTrue(String itemCode);
    
    @Query("""
        SELECT new com.annapurna.dto.MenuItemResponse(
            f.itemId, f.itemCode, f.itemDescription, c.cost
        )
        FROM FoodMst f 
        JOIN CostSheet c ON f.itemId = c.itemId 
        WHERE f.inUse = true AND c.isActive = true
        ORDER BY f.itemCode
    """)
    List<MenuItemResponse> getActiveMenuWithPrices();
}