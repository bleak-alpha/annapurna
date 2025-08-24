package com.annapurna.service;

import com.annapurna.model.CustomerPersonAcc;
import com.annapurna.repository.CustomerPersonAccRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class CustomerService {
    
    private final CustomerPersonAccRepository customerRepository;
    
    public CustomerPersonAcc createCustomer(String name, String phone) {
        String customerNumber = generateCustomerNumber();
        
        CustomerPersonAcc customer = new CustomerPersonAcc();
        customer.setCustomerNumber(customerNumber);
        customer.setName(name);
        customer.setPhone(phone);
        
        return customerRepository.save(customer);
    }
    
    @Transactional(readOnly = true)
    public Optional<CustomerPersonAcc> findByPhone(String phone) {
        return customerRepository.findByPhone(phone);
    }
    
    @Transactional(readOnly = true)
    public List<CustomerPersonAcc> getCustomersWithDues() {
        return customerRepository.findCustomersWithDues();
    }
    
    private String generateCustomerNumber() {
        long count = customerRepository.count() + 1;
        return String.format("CUST%04d", count);
    }
}