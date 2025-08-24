package com.annapurna.service;

import com.annapurna.dto.MenuItemResponse;
import com.annapurna.repository.FoodMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MenuService {
    
    private final FoodMstRepository foodMstRepository;
    
    public List<MenuItemResponse> getActiveMenu() {
        return foodMstRepository.getActiveMenuWithPrices();
    }
}