package com.annapurna.controller;

import com.annapurna.dto.MenuItemResponse;
import com.annapurna.service.MenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/menu")
@RequiredArgsConstructor
public class MenuController {
    
    private final MenuService menuService;
    
    @GetMapping
    public ResponseEntity<List<MenuItemResponse>> getActiveMenu() {
        return ResponseEntity.ok(menuService.getActiveMenu());
    }
}