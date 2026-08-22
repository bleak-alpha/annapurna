package com.annapurna.service;

import com.annapurna.dto.Menu.UpdateNewMenuRequest;
import com.annapurna.dto.Menu.UpdateNewMenuResponse;
import com.annapurna.dto.MenuItemResponse;
import com.annapurna.model.CostSheet;
import com.annapurna.model.FoodMst;
import com.annapurna.repository.CostSheetRepository;
import com.annapurna.repository.FoodMstRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Log4j2
public class MenuService {

    private final FoodMstRepository foodMstRepository;

    private final CostSheetRepository costSheetRepository;

    @Cacheable(value = "activeMenuCache")
    public List<MenuItemResponse> getActiveMenu() {
        log.info("Successfully fetch data from DB");
        return foodMstRepository.getActiveMenuWithPrices();
    }


    @Transactional
    public UpdateNewMenuResponse addNewMenu(UpdateNewMenuRequest updateNewMenuRequest) {
        UpdateNewMenuResponse updateNewMenuResponse = null;
        try {
            FoodMst foodMst = new FoodMst();
            CostSheet costSheet = new CostSheet();

            Optional<FoodMst> response = foodMstRepository
                    .findByitemDescription(updateNewMenuRequest.getItemDescription());

            if (response.isEmpty()) {
                log.info("Menu is Not present in DB hence adding this new Menu in DB");
                foodMst.setItemNumber(updateNewMenuRequest.getItemNumber());
                foodMst.setItemCode(updateNewMenuRequest.getItemCode());
                foodMst.setItemDescription(updateNewMenuRequest.getItemDescription());
                foodMst.setCreationDate(LocalDateTime.now());
                foodMst.setInUse(updateNewMenuRequest.getInUse());
               FoodMst savedData= foodMstRepository.save(foodMst);

                log.info("Food Repository table menu is added Successfully ");
                costSheet.setCost(updateNewMenuRequest.getCost());
                costSheet.setCreationDate(LocalDateTime.now());
                costSheet.setIsActive(updateNewMenuRequest.getIsActive());
                costSheet.setInactiveDate(LocalDateTime.now());
                costSheet.setFoodMst(savedData);
                costSheetRepository.save(costSheet);

                log.info("All menu data is added Successfully ");


                return updateNewMenuResponse = UpdateNewMenuResponse.builder()
                        .responseCode("200")
                        .responseMessage("New Menu Successfully updated in DB")
                        .errorCode("0")
                        .errorMessage("Success").build();
            }
            return updateNewMenuResponse = UpdateNewMenuResponse.builder()
                    .responseCode("202")
                    .responseMessage("Menu is Already Present so Not Updated in DB")
                    .errorCode("202")
                    .errorMessage("Failed").build();
        } catch (Exception e) {
            return updateNewMenuResponse = UpdateNewMenuResponse.builder()
                    .responseCode("500")
                    .responseMessage("Canteen Application Exception Occures: " + e.getMessage())
                    .errorCode("402")
                    .errorMessage("Failed").build();
        }

    }




}