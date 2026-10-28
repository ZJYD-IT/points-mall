package com.demo.points.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.OffsetDateTime;

@Entity
@Table(name = "product")
@Getter
@Setter
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(length = 500)
    private String description;

    @Column(name = "points_cost", nullable = false)
    private long pointsCost;

    @Column(nullable = false)
    private int stock;

    /** 1=上架 0=下架 */
    @Column(nullable = false)
    private short status = 1;

    @Column(name = "sort_no", nullable = false)
    private int sortNo = 0;

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private OffsetDateTime createdAt;

    public boolean isOnSale() {
        return status == 1;
    }
}
