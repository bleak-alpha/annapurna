package com.annapurna.repository;

import com.annapurna.model.CustomerPersonAcc;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerPersonAccRepository extends JpaRepository<CustomerPersonAcc, Integer> {
    
    Optional<CustomerPersonAcc> findByPhone(String phone);
    
    Optional<CustomerPersonAcc> findByCustomerNumber(String customerNumber);
    
    @Query("SELECT c FROM CustomerPersonAcc c WHERE c.isActive = true AND c.totalDue > 0 ORDER BY c.totalDue DESC")
    List<CustomerPersonAcc> findCustomersWithDues();
    
    @Query("SELECT c FROM CustomerPersonAcc c WHERE c.isActive = true ORDER BY c.name")
    List<CustomerPersonAcc> findAllActiveCustomers();
}