package com.demo.points.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

@Entity
@Table(name = "redeem_order")
@Getter
@Setter
public class RedeemOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_no", nullable = false, unique = true, length = 32)
    private String orderNo;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "product_id", nullable = false)
    private Long productId;

    /* ---- 下单时的快照 ---- */
    @Column(name = "product_name", nullable = false, length = 120)
    private String productName;

    @Column(name = "points_cost", nullable = false)
    private long pointsCost;

    @Column(nullable = false)
    private int quantity;

    @Column(name = "total_points", nullable = false)
    private long totalPoints;

    /* ---- 幂等 ---- */
    @Column(name = "idempotency_key", nullable = false, length = 64)
    private String idempotencyKey;

    @Column(nullable = false, length = 20)
    private String status = "CREATED";

    @Column(length = 50)
    private String receiver;

    @Column(length = 20)
    private String phone;

    @Column(length = 300)
    private String address;

    @Column(length = 200)
    private String remark;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private OffsetDateTime createdAt;
}
