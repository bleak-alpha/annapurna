package com.annapurna.service;

import com.annapurna.dto.*;
import com.annapurna.dto.Customer.CustomerDTO;
import com.annapurna.model.*;
import com.annapurna.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
@Log4j2
public class CustomerService {
    
    private final CustomerPersonAccRepository customerRepository;
    private final CustomerOrderHistRepository orderHistRepository;
    
    public CustomerPersonAcc createCustomer(String name, String phone) {
        log.info("Reuqest recived for the add new customer");
        String customerNumber = generateCustomerNumber();

        Optional<CustomerPersonAcc> data= findByPhone(phone);
        if(data.isEmpty()) {
            CustomerPersonAcc customer = new CustomerPersonAcc();
            customer.setCustomerNumber(customerNumber);
            customer.setName(name);
            customer.setPhone(phone);
           return customerRepository.save(customer);
        } else {

            return data.get();
        }
    }
    
    @Transactional(readOnly = true)
    public Optional<CustomerPersonAcc> findByPhone(String phone) {
        return customerRepository.findByPhone(phone);
    }
    
    @Transactional(readOnly = true)
    public List<CustomerDuesResponse> getCustomersWithDues() {
        List<CustomerPersonAcc> customers = customerRepository.findCustomersWithDues();
        
        return customers.stream()
            .map(this::mapToCustomerDuesResponse)
            .collect(Collectors.toList());
    }
    
    private CustomerDuesResponse mapToCustomerDuesResponse(CustomerPersonAcc customer) {
        List<CustomerOrderHist> unpaidHist = orderHistRepository.findUnpaidOrdersByCustomer(customer.getCustomerId());
        
        List<UnpaidOrderLineDto> unpaidLines = unpaidHist.stream()
            .map(hist -> {
                OrderLine line = hist.getOrderLine();
                return new UnpaidOrderLineDto(
                    line.getLineId(),
                    line.getOrderHeader().getOrderNumber(),
                    line.getCreationDate(),
                    line.getFoodMst().getItemDescription(),
                    line.getQuantity(),
                    line.getTotalCost()
                );
            })
            .collect(Collectors.toList());
        
        return new CustomerDuesResponse(
            customer.getCustomerId(),
            customer.getCustomerNumber(),
            customer.getName(),
            customer.getPhone(),
            customer.getTotalDue(),
            unpaidLines
        );
    }
    
    private String generateCustomerNumber() {
        long count = customerRepository.count() + 1;
        return String.format("CUST%04d", count);
    }


    public List<CustomerDTO> getallCustomerData() {

        List<CustomerPersonAcc> entity = customerRepository.findAll();

        List<CustomerDTO> list = new ArrayList<>();

        for (CustomerPersonAcc data : entity) {
            list.add(new CustomerDTO(
                    data.getCustomerNumber(),
                    data.getName()
            ));
        }

        return list;
    }
}