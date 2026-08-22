package com.annapurna.model.customer;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UpdateDeleteRequest {

    @NotBlank(message = "Action is required")
    private String action;

    private String customerName;

    @NotBlank(message = "Customer number is required")
    private String customerNo;

    private String phone;

    private String email;
}