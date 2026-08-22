package com.annapurna.repository;

import com.annapurna.model.CostSheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface CostSheetRepository extends JpaRepository<CostSheet, Integer> {
    
    @Query("SELECT cs FROM CostSheet cs WHERE cs.foodMst.itemId = :itemId AND cs.isActive = true")
    Optional<CostSheet> findActiveCostForItem(@Param("itemId") Integer itemId);
    
    @Query("SELECT cs FROM CostSheet cs WHERE cs.foodMst.itemId = :itemId ORDER BY cs.creationDate DESC")
    List<CostSheet> findCostHistoryForItem(@Param("itemId") Integer itemId);
}