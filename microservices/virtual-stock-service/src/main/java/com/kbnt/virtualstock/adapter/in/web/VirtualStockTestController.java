package com.kbnt.virtualstock.adapter.in.web;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/v1/virtual-stock/test")
@CrossOrigin(origins = "*")
public class VirtualStockTestController {

    private final Map<String, Object> testStocks = new HashMap<>();
    
    public VirtualStockTestController() {
        // Initialize with test data
        testStocks.put("AAPL", Map.of("symbol", "AAPL", "quantity", 100, "price", 150.00));
        testStocks.put("GOOGL", Map.of("symbol", "GOOGL", "quantity", 50, "price", 2800.00));
        testStocks.put("MSFT", Map.of("symbol", "MSFT", "quantity", 75, "price", 330.00));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "virtual-stock-service");
        response.put("timestamp", new Date().toString());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/stocks")
    public ResponseEntity<List<Object>> getAllStocks() {
        return ResponseEntity.ok(new ArrayList<>(testStocks.values()));
    }

    @GetMapping("/stocks/{symbol}")
    public ResponseEntity<Object> getStock(@PathVariable String symbol) {
        Object stock = testStocks.get(symbol.toUpperCase());
        if (stock != null) {
            return ResponseEntity.ok(stock);
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/stocks")
    public ResponseEntity<Object> createStock(@RequestBody Map<String, Object> stock) {
        String symbol = (String) stock.get("symbol");
        if (symbol != null) {
            testStocks.put(symbol.toUpperCase(), stock);
            return ResponseEntity.ok(stock);
        }
        return ResponseEntity.badRequest().build();
    }
}
