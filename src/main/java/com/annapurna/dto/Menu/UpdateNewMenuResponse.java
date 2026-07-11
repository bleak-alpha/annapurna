package com.annapurna.dto.Menu;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UpdateNewMenuResponse {

    private String responseCode;
    private String responseMessage;
    private String errorCode;
    private String errorMessage;
}
