package com.annapurna.service;

import com.annapurna.model.CustomerPaymentHist;
import com.annapurna.repository.CustomerPaymentHistRepository;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.log4j.Log4j2;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.util.CellRangeAddress;
import org.apache.poi.xddf.usermodel.chart.*;
import org.apache.poi.xssf.usermodel.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Log4j2
public class ReportService {

    @Autowired
    private CustomerPaymentHistRepository customerPaymentHistRepository;

    public XSSFWorkbook generateWorkbook() throws Exception {

        LocalDate today = LocalDate.now();

        LocalDateTime start = today.atStartOfDay();

        LocalDateTime end = today.plusDays(1).atStartOfDay();
        List<CustomerPaymentHist> data =
                customerPaymentHistRepository.findPaymentsBetweenDates(start, end);

        XSSFWorkbook workbook = new XSSFWorkbook();

        if(data.isEmpty()){
            log.info("No sales found");
            return workbook;
        }
        XSSFSheet sheet =workbook.createSheet(today + "-Data");
        Row header =sheet.createRow(0);
        header.createCell(0).setCellValue("Sr No");
        header.createCell(1).setCellValue("Customer Name");
        header.createCell(2).setCellValue("Payment Mode");
        header.createCell(3).setCellValue("Amount");
        header.createCell(4).setCellValue("Payment Date");

        int rowNum = 1;
        int srNo = 1;
        for(CustomerPaymentHist entity : data){
            Row row = sheet.createRow( rowNum++);
            row.createCell(0).setCellValue(srNo++);
            row.createCell(1).setCellValue(entity.getCustomer().getName());
            row.createCell(2).setCellValue(entity.getPaymentMode());
            row.createCell(3).setCellValue(entity.getAmountPaid().doubleValue());
            row.createCell(4).setCellValue(entity.getPaymentDate().toString());
        }

        Map<String, BigDecimal> paymentSummary =
                data.stream()
                        .collect(
                                Collectors.groupingBy(
                                        CustomerPaymentHist::getPaymentMode,
                                        Collectors.reducing(
                                                BigDecimal.ZERO,
                                                CustomerPaymentHist::getAmountPaid,
                                                BigDecimal::add
                                        )
                                )
                        );

        XSSFSheet pieSheet =workbook.createSheet("HistoricalData of Sale");
        Row pieHeader =pieSheet.createRow(0);
        pieHeader.createCell(0).setCellValue("Sr No");
        pieHeader.createCell(1).setCellValue("Payment Mode");
        pieHeader.createCell(2).setCellValue("Amount");

        int pieRow = 1;
        int pieSrNo = 1;
        for(Map.Entry<String,BigDecimal> entry: paymentSummary.entrySet()){
            Row row =pieSheet.createRow(pieRow++);
            row.createCell(0).setCellValue(pieSrNo++);
            row.createCell(1).setCellValue(entry.getKey());
            row.createCell(2).setCellValue(entry.getValue().doubleValue() );
        }

        XSSFDrawing drawing =pieSheet.createDrawingPatriarch();
        XSSFClientAnchor anchor =drawing.createAnchor(
                0,
                0,
                0,
                0,
                4,
                1,
                12,
                15);

        XSSFChart chart =drawing.createChart(anchor);
        chart.setTitleText("Today's Revenue Distribution");
        chart.setTitleOverlay(false);
        XDDFChartLegend legend =chart.getOrAddLegend();
        legend.setPosition(LegendPosition.RIGHT);
        XDDFDataSource<String> categories =XDDFDataSourcesFactory
                .fromStringCellRange(
                        pieSheet,
                        new CellRangeAddress(
                                1,
                                paymentSummary.size(),
                                1,
                                1
                        )
                );

        XDDFNumericalDataSource<Double> values =
                XDDFDataSourcesFactory
                        .fromNumericCellRange(
                                pieSheet,
                                new CellRangeAddress(
                                        1,
                                        paymentSummary.size(),
                                        2,
                                        2
                                )
                        );

        XDDFPieChartData pieData =
                (XDDFPieChartData)
                        chart.createData(
                                ChartTypes.PIE,
                                null,
                                null
                        );

        pieData.setVaryColors(true);
        pieData.addSeries(categories,values);
        chart.plot(pieData);

        for(int i=0;i<5;i++){
            sheet.autoSizeColumn(i);
        }
        for(int i=0;i<3;i++){
            pieSheet.autoSizeColumn(i);
        }
        return workbook;
    }


    public void downloadPaymentData(HttpServletResponse response) throws Exception {
        XSSFWorkbook workbook =generateWorkbook();
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition","attachment; filename=payment-report.xlsx");
        workbook.write(response.getOutputStream());
        workbook.close();
    }
}