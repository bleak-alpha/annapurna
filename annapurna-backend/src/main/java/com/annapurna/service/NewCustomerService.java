package com.annapurna.service;

import com.annapurna.model.customer.NewCustomerRequest;
import com.annapurna.model.customer.NewCustomerResponse;
import com.annapurna.model.customer.UpdateDeleteRequest;


public interface NewCustomerService {

    NewCustomerResponse addCustomer(NewCustomerRequest request);

    NewCustomerResponse updateDeleteCustData(UpdateDeleteRequest request);
}
