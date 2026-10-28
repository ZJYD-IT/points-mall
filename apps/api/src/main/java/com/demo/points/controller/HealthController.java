package com.demo.points.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.Map;

@RestController
public class HealthController {

    /** 一键发布流水线会打这个接口做健康检查 */
    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of("status", "UP", "time", OffsetDateTime.now().toString());
    }
}
