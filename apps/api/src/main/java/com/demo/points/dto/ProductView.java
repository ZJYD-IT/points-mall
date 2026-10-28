package com.demo.points.dto;

import com.demo.points.entity.Product;

public record ProductView(Long id, String name, String imageUrl, String description,
                          long pointsCost, int stock, short status) {
    public static ProductView of(Product p) {
        return new ProductView(p.getId(), p.getName(), p.getImageUrl(), p.getDescription(),
                p.getPointsCost(), p.getStock(), p.getStatus());
    }
}
