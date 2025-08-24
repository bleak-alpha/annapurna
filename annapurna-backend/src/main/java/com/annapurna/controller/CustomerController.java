package com.annapurna.controller;

import com.annapurna.model.CustomerPersonAcc;
import com.annapurna.service.CustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/customers")
@RequiredArgsConstructor
public class CustomerController {
    
    private final CustomerService customerService;
    
    @PostMapping
    public ResponseEntity<CustomerPersonAcc> createCustomer(@RequestBody Map<String, String> request) {
        String name = request.get("name");
        String phone = request.get("phone");
        
        CustomerPersonAcc customer = customerService.createCustomer(name, phone);
        return ResponseEntity.ok(customer);
    }
    
    @GetMapping("/search")
    public ResponseEntity<CustomerPersonAcc> findByPhone(@RequestParam String phone) {
        return customerService.findByPhone(phone)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/dues")
    public ResponseEntity<List<CustomerPersonAcc>> getCustomersWithDues() {
        return ResponseEntity.ok(customerService.getCustomersWithDues());
    }
}