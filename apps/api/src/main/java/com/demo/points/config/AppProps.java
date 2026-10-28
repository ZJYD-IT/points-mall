package com.demo.points.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** 对应 application.yml 里的 app.* */
@ConfigurationProperties(prefix = "app")
public record AppProps(Jwt jwt, Cors cors) {
    public record Jwt(String secret, long ttlMinutes) {}
    public record Cors(String allowedOrigins) {}
}
