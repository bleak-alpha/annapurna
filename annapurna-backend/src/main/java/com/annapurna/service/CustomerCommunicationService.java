package com.annapurna.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class CustomerCommunicationService {

    @Value("{$.whatsapp.access-token}")
    private String accessToken;

    @Value("{$.whatsapp.phonenumber-id}")
    private String phoneId;


}
