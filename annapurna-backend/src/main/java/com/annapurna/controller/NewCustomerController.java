package com.annapurna.controller;


import com.annapurna.constant.ApiConstant;
import com.annapurna.constant.AppConstant;
import com.annapurna.model.customer.NewCustomerRequest;
import com.annapurna.model.customer.NewCustomerResponse;
import com.annapurna.model.customer.UpdateDeleteRequest;
import com.annapurna.model.generic.GenericResponse;
import com.annapurna.service.NewCustomerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static com.annapurna.enums.ResponseCode.INA_CANTEEN_CODE_99999;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class NewCustomerController {


    @Autowired
    private NewCustomerService newCustomerService;

    @PostMapping(ApiConstant.ADD_CUSTOMER)
    public ResponseEntity<NewCustomerResponse> addCustomer(@Valid @RequestBody NewCustomerRequest request) {
        try {
            NewCustomerResponse response = newCustomerService.addCustomer(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            NewCustomerResponse response = NewCustomerResponse.builder()
                    .genericResponse(GenericResponse.builder()
                            .errorMessage(INA_CANTEEN_CODE_99999.getValue())
                            .errorCode(INA_CANTEEN_CODE_99999.getKey()).build()).build();
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response);
        }
    }

    @PostMapping(ApiConstant.UPDATE_ORDER)
    public ResponseEntity<NewCustomerResponse> updateDeleteCustomer(@Valid @RequestBody UpdateDeleteRequest request) {
        try {
            NewCustomerResponse response = newCustomerService.updateDeleteCustData(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            NewCustomerResponse response = NewCustomerResponse.builder()
                    .genericResponse(GenericResponse.builder()
                            .errorMessage(INA_CANTEEN_CODE_99999.getValue())
                            .errorCode(INA_CANTEEN_CODE_99999.getKey()).build()).build();
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response);
        }
    }
}

