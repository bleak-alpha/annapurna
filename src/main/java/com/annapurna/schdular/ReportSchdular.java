package com.annapurna.schdular;

import com.annapurna.service.ReportService;
import lombok.extern.log4j.Log4j2;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import jakarta.mail.internet.MimeMessage;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;

@Component
@Log4j2
public class ReportSchdular {

    @Value("${schdular.report.active}")
    private boolean isActive;

    @Value("${report.email.receiveremail}")
    private String receiverEmail;

    @Autowired
    private ReportService reportService;

    @Autowired
    private JavaMailSender javaMailSender;


    @Scheduled(cron = "${cron.report.cron}")
    public void sendReport() {
        if(!isActive){
            log.info("Please Enable the schdular for send the payment report");
        }
        try {
            log.info("Sending daily payment report");
            LocalDate date = LocalDate.now();
            XSSFWorkbook workbook = reportService.generateWorkbook();
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            workbook.write(outputStream);
            workbook.close();

            MimeMessage message = javaMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true);
            helper.setTo(receiverEmail);
            helper.setSubject("Payment Report : " + date);
            helper.setText("Dear Admin,\n\n" +
                            "Kindly find attached payment report for "
                            + date);
            helper.addAttachment("payment-report.xlsx", new ByteArrayResource(
                    outputStream.toByteArray()));
            javaMailSender.send(message);
            log.info("Report sent successfully");
        }
        catch(Exception e){
            log.error("Error while sending report", e.getMessage());
        }
    }
}