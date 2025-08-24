package com.annapurna.controller;

import com.annapurna.health.DatabaseHealthIndicator;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@RequiredArgsConstructor
public class HealthController {
    
    private final DatabaseHealthIndicator databaseHealthIndicator;
    
    @GetMapping
    public ResponseEntity<Map<String, Object>> healthCheck() {
        var health = databaseHealthIndicator.health();
        
        if ("UP".equals(health.getStatus().getCode())) {
            return ResponseEntity.ok(Map.of(
                "status", "UP",
                "database", "Connected"
            ));
        } else {
            return ResponseEntity.status(503).body(Map.of(
                "status", "DOWN",
                "database", "Disconnected"
            ));
        }
    }
}