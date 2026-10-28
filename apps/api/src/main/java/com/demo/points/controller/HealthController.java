package com.demo.points.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class HealthController {

    private final JdbcTemplate jdbc;

    public HealthController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * 健康检查。
     * 必须真的摸一次数据库 —— 只返回 "UP" 的假健康检查比没有更危险：
     * 数据库挂了它还报健康，发布流水线的健康检查和监控告警就全都失效了。
     *
     * 数据库不可用时返回 503，这样：
     *   - deploy.sh 的健康检查会判定失败并回滚
     *   - health-watch.sh / fail-drill.sh 能真正发现数据库故障
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("time", OffsetDateTime.now().toString());
        try {
            Integer one = jdbc.queryForObject("select 1", Integer.class);
            if (one == null || one != 1) {
                throw new IllegalStateException("数据库返回异常");
            }
            body.put("db", "UP");
            body.put("status", "UP");
            return ResponseEntity.ok(body);
        } catch (Exception e) {
            body.put("db", "DOWN");
            body.put("status", "DOWN");
            body.put("reason", e.getClass().getSimpleName());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(body);
        }
    }
}
