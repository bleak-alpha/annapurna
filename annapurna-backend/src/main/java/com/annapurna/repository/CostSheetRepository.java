package com.annapurna.repository;

import com.annapurna.model.CostSheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface CostSheetRepository extends JpaRepository<CostSheet, Integer> {
    Optional<CostSheet> findByItemIdAndIsActiveTrue(Integer itemId);
}