package com.demo.points.dto;

import com.demo.points.entity.RedeemOrder;

import java.time.OffsetDateTime;

public record OrderView(Long id, String orderNo, Long productId, String productName,
                        long pointsCost, int quantity, long totalPoints, String status,
                        String receiver, String phone, String address, String remark,
                        OffsetDateTime createdAt) {
    public static OrderView of(RedeemOrder o) {
        return new OrderView(o.getId(), o.getOrderNo(), o.getProductId(), o.getProductName(),
                o.getPointsCost(), o.getQuantity(), o.getTotalPoints(), o.getStatus(),
                o.getReceiver(), o.getPhone(), o.getAddress(), o.getRemark(), o.getCreatedAt());
    }
}
