package com.demo.points.dto;

import com.demo.points.entity.PointsLedger;

import java.time.OffsetDateTime;

public record LedgerView(Long id, long delta, long balanceAfter, String bizType,
                         String bizId, String remark, OffsetDateTime createdAt) {
    public static LedgerView of(PointsLedger l) {
        return new LedgerView(l.getId(), l.getDelta(), l.getBalanceAfter(),
                l.getBizType(), l.getBizId(), l.getRemark(), l.getCreatedAt());
    }
}
