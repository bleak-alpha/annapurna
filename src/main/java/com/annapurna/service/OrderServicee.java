package com.annapurna.service;

import com.annapurna.dto.Order.OrderRequest;
import com.annapurna.dto.Order.UpdateOrderRequest;
import com.annapurna.model.generic.GenericResponse;
import com.annapurna.service.impl.OrderServiceImpl;


public interface OrderServicee  {


    GenericResponse addOrder(OrderRequest request);

    GenericResponse updateOrder(UpdateOrderRequest request);
}
