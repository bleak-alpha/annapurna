package com.annapurna.model.generic;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class GenericResponse {

    private int errorCode;

    private String errorMessage;
}
