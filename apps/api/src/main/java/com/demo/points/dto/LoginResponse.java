package com.demo.points.dto;

public record LoginResponse(String token, String role, Long id, String displayName, Long points) {
}
