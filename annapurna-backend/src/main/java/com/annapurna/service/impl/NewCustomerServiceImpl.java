package com.annapurna.service.impl;

import com.annapurna.constant.AppConstant;
import com.annapurna.constant.ExceptionConstant;
import com.annapurna.exception.DatabaseOperationException;
import com.annapurna.model.CustomerPersonAcc;
import com.annapurna.model.customer.NewCustomerRequest;
import com.annapurna.model.customer.NewCustomerResponse;
import com.annapurna.model.customer.UpdateDeleteRequest;
import com.annapurna.model.generic.GenericResponse;
import com.annapurna.repository.CustomerPersonAccRepository;
import com.annapurna.service.NewCustomerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;
import static com.annapurna.enums.ResponseCode.*;
import com.annapurna.constant.AppConstant.*;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NewCustomerServiceImpl implements NewCustomerService {

    @Autowired
    private CustomerPersonAccRepository repository;


    @Override
    @Transactional
    public NewCustomerResponse addCustomer(NewCustomerRequest request){
        try {
           Optional<CustomerPersonAcc> data = repository.findByPhoneAndCustomerEmail(request.getPhone(), request.getEmail());
            if(!data.isEmpty()){
               return buildResponse(INA_CANTEEN_CODE_202.getKey(),INA_CANTEEN_CODE_202.getValue());
            }
            String customerNo = generateCustomerNumber();
            CustomerPersonAcc entity = new CustomerPersonAcc();
            entity.setCustomerEmail(request.getEmail());
            entity.setPhone(request.getPhone());
            entity.setName(request.getCustomerName());
            entity.setCustomerNumber(customerNo);
            repository.save(entity);
            return buildResponse(INA_CANTEEN_CODE_200.getKey(), INA_CANTEEN_CODE_200.getValue());
        } catch (Exception e) {
            throw new DatabaseOperationException(ExceptionConstant.DB_OPERATION__INSERATION_FAILED_EXCEPTION, e);
        }
    }


    @Override
    @Transactional
    public NewCustomerResponse updateDeleteCustData(UpdateDeleteRequest request){
        try{
            Optional<CustomerPersonAcc> data =repository.findByCustomerNumber(request.getCustomerNo());
            if(data.isEmpty()){
                return buildResponse(INA_CANTEEN_CODE_201.getKey(), INA_CANTEEN_CODE_201.getValue());
            }
            CustomerPersonAcc entity = data.get();
            if(AppConstant.UPDATE.equalsIgnoreCase(request.getAction())){
                if(isValid(request.getCustomerName())) {
                    entity.setName(request.getCustomerName());
                }
                if(isValid(request.getPhone())) {
                    entity.setPhone(request.getPhone());
                }
                if(isValid(request.getEmail())) {
                    entity.setCustomerEmail(request.getEmail());
                }
                entity.setCreationDate(LocalDateTime.now());
                repository.save(entity);
                return buildResponse(INA_CANTEEN_CODE_204.getKey(), INA_CANTEEN_CODE_204.getValue());
            } else if (AppConstant.DELETE.equalsIgnoreCase(request.getAction())) {
                if(isValid(request.getCustomerNo())) {
                    repository.deleteByCustomerNumberAndPhone(request.getCustomerNo(), request.getPhone());
                }
                return buildResponse(INA_CANTEEN_CODE_203.getKey(), INA_CANTEEN_CODE_203.getValue());
            } else {
                return buildResponse(INA_CANTEEN_CODE_99999.getKey(), INA_CANTEEN_CODE_99999.getValue());
            }
        } catch (Exception e){
                throw  new RuntimeException(ExceptionConstant.DB_OPERATION_FAILED_EXCEPTION, e);
        }
    }


    private String generateCustomerNumber() {
        long count = repository.count() + 1;
        return String.format(AppConstant.CUSTOMER_ID_FORMATTER, count);
    }

    private boolean isValid(String value){
        if(value != null && !value.isBlank()){
            return true;
        }
        return false;
    }


    public NewCustomerResponse buildResponse(int key, String value){
        return NewCustomerResponse.builder()
                .genericResponse(
                        GenericResponse.builder()
                                .errorCode(key)
                                .errorMessage(value)
                                .build()
                )
                .build();
    }
}

