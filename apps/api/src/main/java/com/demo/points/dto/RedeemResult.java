package com.demo.points.dto;

public record RedeemResult(Long orderId, String orderNo, long totalPoints,
                           long balanceAfter, boolean repeated) {
}
