package com.annapurna.model.customer;

import com.annapurna.model.generic.GenericResponse;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class NewCustomerResponse {

     private GenericResponse genericResponse;
}
