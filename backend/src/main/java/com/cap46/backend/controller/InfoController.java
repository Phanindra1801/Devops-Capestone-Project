
package com.cap46.backend.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class InfoController {

    @GetMapping("/api/info")
    public Map<String, Object> getInfo() {
        return Map.of(
            "application", "CAP-46",
            "version", "1.0.0",
            "description", "Nginx Reverse Proxy Failure Isolation",
            "backend", "Spring Boot",
            "javaVersion", System.getProperty("java.version"),
            "status", "Running"
        );
    }
}
