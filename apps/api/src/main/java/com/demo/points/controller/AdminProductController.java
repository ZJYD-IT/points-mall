package com.demo.points.controller;

import com.demo.points.dto.ProductSaveRequest;
import com.demo.points.dto.ProductView;
import com.demo.points.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 后台商品管理：需要 ROLE_ADMIN */
@RestController
@RequestMapping("/admin/products")
public class AdminProductController {

    private final ProductService productService;

    public AdminProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public List<ProductView> list() {
        return productService.listAll().stream().map(ProductView::of).toList();
    }

    @PostMapping
    public ProductView create(@Valid @RequestBody ProductSaveRequest req) {
        return ProductView.of(productService.create(req));
    }

    @PutMapping("/{id}")
    public ProductView update(@PathVariable Long id, @Valid @RequestBody ProductSaveRequest req) {
        return ProductView.of(productService.update(id, req));
    }
}
