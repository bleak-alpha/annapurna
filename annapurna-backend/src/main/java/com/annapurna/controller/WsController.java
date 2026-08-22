package com.annapurna.controller;

import com.annapurna.dto.WS.WsOrderRequest;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/api")
@Log4j2
public class WsController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/messagebroadcast")
    public void updateOrder(WsOrderRequest message) {
        log.info("Order Data is : " +message.getTotalPayment());
        log.info("Order Data: {}", message);
        messagingTemplate.convertAndSend(
                "/topic/orders",
                message
        );
    }
}
