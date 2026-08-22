package com.annapurna.controller;

import com.annapurna.service.ReportService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;



@RestController
@Log4j2
@RequestMapping("/api/report")
public class ReportController {

    @Autowired
    private ReportService reportService;

    @GetMapping("/paymentreport")
    public void downloadPaymentData(HttpServletResponse httpServletResponse) throws Exception{
        log.info("Request Recived");
        reportService.downloadPaymentData(httpServletResponse);
    }


}
