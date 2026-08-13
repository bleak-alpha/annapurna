package com.annapurna.service.impl;

import com.annapurna.constant.AppConstant;
import com.annapurna.dto.Order.OrderRequest;
import com.annapurna.dto.Order.UpdateOrderRequest;
import com.annapurna.exception.DatabaseOperationException;
import com.annapurna.model.InaAuditTable;
import com.annapurna.model.generic.GenericResponse;
import com.annapurna.repository.CustomerPersonAccRepository;
import com.annapurna.repository.INACanteenAuditReporsitory;
import com.annapurna.service.OrderServicee;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.Optional;


import static com.annapurna.constant.ExceptionConstant.DB_OPERATION__INSERATION_FAILED_EXCEPTION;
import static com.annapurna.enums.ResponseCode.*;

@Service
@Log4j2
@NoArgsConstructor(force = true)
@AllArgsConstructor
public class OrderServiceImpl implements OrderServicee {

    private final INACanteenAuditReporsitory reporsitory;

    private final CustomerPersonAccRepository customerPersonAccRepository;



    @Override
    @Transactional
    public GenericResponse addOrder(OrderRequest request) {
        try {
            InaAuditTable entity = new InaAuditTable();
            entity.setCustomerName(request.getCustomerName());
            entity.setCustomerId(request.getCustomerId());
            entity.setEatMode(request.getEatMode());
            entity.setOrderDetails(request.getOrderDetails());
            entity.setTotalPayment(request.getTotalPayment());
            entity.setPaidAmount(request.getPaidAmount());
            entity.setRemainingAmount(request.getRemainingAmount());
            entity.setPaymentMode(request.getPaymentMode());
            entity.setOrderStatus(request.getOrderStatus());
            entity.setCreatedDate(LocalDateTime.now());
            entity.setUpdatedAt(LocalDateTime.now());
            entity.setTableUpdateStatus(AppConstant.TWO);
            InaAuditTable savedEntity = reporsitory.save(entity);
            return buildResponse(INA_CANTEEN_CODE_200.getKey(), String.format(AppConstant.CUST_ID_FOR_SAVED_ORDER, savedEntity.getId()));
        } catch (Exception e) {
            throw new DatabaseOperationException(DB_OPERATION__INSERATION_FAILED_EXCEPTION, e);
        }
    }

    @Override
    @Transactional
    public GenericResponse updateOrder(UpdateOrderRequest request) {
        try {
            Optional<InaAuditTable> entity = reporsitory.findById(request.getId());
            if(entity.isEmpty()) {
                return buildResponse(INA_CANTEEN_CODE_201.getKey(), INA_CANTEEN_CODE_201.getValue());
            }
            InaAuditTable entitydata= entity.get();
            boolean dbUpdateStatus= saveDataInTable(entitydata,request);
            if(dbUpdateStatus){
                return buildResponse(INA_CANTEEN_CODE_200.getKey(), INA_CANTEEN_CODE_200.getValue());
            } else {
                return buildResponse(INA_CANTEEN_CODE_109.getKey(), INA_CANTEEN_CODE_109.getValue());
            }
        } catch (Exception e) {
            throw new DatabaseOperationException("An Excpetion Occurred during updating data in Table ", e);
        }
    }



    public boolean saveDataInTable(InaAuditTable data, UpdateOrderRequest request) {
        data.setCustomerName(request.getCustomerName());
        data.setCustomerId(request.getCustomerId());
        data.setEatMode(request.getEatMode());
        data.setOrderDetails(request.getOrderDetails());
        data.setTotalPayment(request.getTotalPayment());
        data.setPaidAmount(request.getPaidAmount());
        data.setRemainingAmount(request.getRemainingAmount());
        data.setDuePaidAmount(request.getDuePaidAmount());
        data.setPaymentMode(request.getPaymentMode());
        data.setOrderStatus(request.getOrderStatus());
        data.setUpdatedAt(LocalDateTime.now());
        reporsitory.save(data);
        return true;
    }


    private GenericResponse buildResponse(int key, String value){
        return GenericResponse.builder()
                .errorCode(key)
                .errorMessage(value).build();
    }

}
