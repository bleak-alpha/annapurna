package com.annapurna.schdular;

import com.annapurna.config.ExecutorConfig;
import com.annapurna.constant.ApiConstant;
import com.annapurna.constant.AppConstant;
import com.annapurna.constant.LogConstant;
import com.annapurna.model.CustomerPersonAcc;
import com.annapurna.model.InaAuditTable;
import com.annapurna.repository.CustomerPersonAccRepository;
import com.annapurna.repository.INACanteenAuditReporsitory;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.stream.Collectors;

@Component
@Log4j2
public class OrderDataUpdateScheduler {

    @Value("${scheduler.updatedata.fulldata.active}")
    private boolean isFinalUpdate;

    @Value("${scheduler.updatedata.customerdues.active}")
    private boolean isCustomerDuesUpdates;

    @Value("${scheduler.updatedata.orderdata.active}")
    private boolean isOrderDataUpdates;

    private final INACanteenAuditReporsitory repository;

    private final CustomerPersonAccRepository custRepository;

    private final ExecutorService orderDataExecutor;



    public OrderDataUpdateScheduler(INACanteenAuditReporsitory repository, CustomerPersonAccRepository custRepository, ExecutorConfig executorConfig) {
        this.repository = repository;
        this.custRepository = custRepository;
        this.orderDataExecutor = executorConfig.orderDataExecutor();
    }


    @Scheduled(cron = ApiConstant.FULL_DATA_UPDATE_SCHEDULER_CRON)
    public void processBackendData() {
        if(isFinalUpdate){
            log.info(LogConstant.SCHEDULER_STARTED_SUCCESSFULLY,AppConstant.FULL_DATA_UPDATE_SCHEDULER);
            collectAndData();
            log.info(LogConstant.SCHEDULER_COMPLETED_SUCCESSFULLY,AppConstant.FULL_DATA_UPDATE_SCHEDULER);
        }
        log.info(LogConstant.SKIPPING_SCHEDULER,AppConstant.FULL_DATA_UPDATE_SCHEDULER);
    }


    private void collectAndData(){
        List<InaAuditTable> data=repository.findBytableUpdateStatusIn(List.of(AppConstant.TWO, AppConstant.THREE, AppConstant.FOUR));
        if(data.isEmpty()){
            log.info(LogConstant.NO_DATA_FOUND);
            return;
        }
        Map<String, List<InaAuditTable>> groupedData = data.stream()
                .collect(Collectors.groupingBy(
                        InaAuditTable::getTableUpdateStatus
                ));
        CompletableFuture<Void> status2Future = CompletableFuture.runAsync(
                () -> processFullData(groupedData.getOrDefault(AppConstant.TWO, List.of())), orderDataExecutor);
        CompletableFuture<Void> status3Future = CompletableFuture.runAsync(
                () -> processCustomerData(groupedData.getOrDefault(AppConstant.THREE, List.of())), orderDataExecutor);
        CompletableFuture<Void> status4Future = CompletableFuture.runAsync(
                () -> processOrdersData(groupedData.getOrDefault(AppConstant.FOUR, List.of())), orderDataExecutor);
    }
    private void processOrdersData(List<InaAuditTable> auditTable) {

    }

    private void processCustomerData(List<InaAuditTable> auditTable) {
        for(InaAuditTable data: auditTable){
           String customerNo = data.getCustomerId();
           Optional<CustomerPersonAcc> request = custRepository.findByCustomerNumber(customerNo);
           CustomerPersonAcc entity= request.get();
           if(request.isEmpty()){
               log.info("Missing Customer Id");
           }
           BigDecimal previousDues= entity.getTotalDue();
            if (previousDues.compareTo(BigDecimal.ZERO) > 0 && data.getRemainingAmount() > 0) {
              previousDues = previousDues.add(
                        BigDecimal.valueOf(data.getRemainingAmount()));
              entity.setTotalDue(previousDues);
            }
        }
    }

    private void processFullData(List<InaAuditTable> auditTable) {
        processCustomerData(auditTable);
        processOrdersData(auditTable);
    }

}




