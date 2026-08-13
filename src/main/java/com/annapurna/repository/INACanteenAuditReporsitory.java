package com.annapurna.repository;

import com.annapurna.model.InaAuditTable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface INACanteenAuditReporsitory extends JpaRepository<InaAuditTable, Long> {

    List<InaAuditTable> findByCreatedDateBetween(LocalDateTime start, LocalDateTime end);

    Optional<InaAuditTable> findById(Long id);

    List<InaAuditTable> findBytableUpdateStatusIn(List<String> value);
}
