package com.annapurna.controller;

import com.annapurna.dto.Menu.UpdateNewMenuRequest;
import com.annapurna.dto.Menu.UpdateNewMenuResponse;
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

    @PostMapping("/add")
    public ResponseEntity<?> addNewMenu(
            @RequestBody UpdateNewMenuRequest updateNewMenuRequest) {
        try {
            UpdateNewMenuResponse response = menuService.addNewMenu(updateNewMenuRequest);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            UpdateNewMenuResponse errorResponse =
                    UpdateNewMenuResponse.builder()
                            .responseCode("500")
                            .responseMessage(e.getMessage())
                            .errorCode("500")
                            .errorMessage("Failed")
                            .build();
            return ResponseEntity.internalServerError()
                    .body(errorResponse);
        }
    }






}