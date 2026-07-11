package com.annapurna.dto.Customer;

public class CustomerDTO {

    private String customerNumber;
    private String name;

    public CustomerDTO(String customerNumber, String name) {
        this.customerNumber = customerNumber;
        this.name = name;
    }

    public String getCustomerNumber() { return customerNumber; }
    public String getName() { return name; }
}