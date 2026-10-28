package com.demo.points.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

@Entity
@Table(name = "app_user")
@Getter
@Setter
public class AppUser {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 20)
    private String phone;

    @Column(length = 50)
    private String nickname;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    /**
     * 积分余额。注意：这是冗余字段，任何变动都必须
     * 1) 写 points_ledger  2) 在同一个事务里改这里
     * 并用 @Version 乐观锁防止并发覆盖（第 2 阶段兑换流程会用到）。
     */
    @Column(nullable = false)
    private long points;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(nullable = false)
    private boolean enabled = true;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private OffsetDateTime createdAt;
}
