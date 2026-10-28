package com.demo.points.service;

import com.demo.points.common.BizException;
import com.demo.points.dto.ProductSaveRequest;
import com.demo.points.entity.Product;
import com.demo.points.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ProductService {

    private final ProductRepository repo;

    public ProductService(ProductRepository repo) {
        this.repo = repo;
    }

    public List<Product> listOnSale() {
        return repo.findByStatusOrderBySortNoDescIdDesc((short) 1);
    }

    public List<Product> listAll() {
        return repo.findAllByOrderByStatusDescSortNoDescIdDesc();
    }

    @Transactional
    public Product create(ProductSaveRequest req) {
        Product p = new Product();
        apply(p, req);
        return repo.save(p);
    }

    @Transactional
    public Product update(Long id, ProductSaveRequest req) {
        Product p = repo.findById(id).orElseThrow(() -> new BizException("商品不存在"));
        apply(p, req);
        return repo.save(p);
    }

    private void apply(Product p, ProductSaveRequest req) {
        p.setName(req.name());
        p.setImageUrl(req.imageUrl());
        p.setDescription(req.description());
        p.setPointsCost(req.pointsCost());
        p.setStock(req.stock());
        p.setStatus(req.status() == null ? (short) 1 : req.status());
        p.setSortNo(req.sortNo() == null ? 0 : req.sortNo());
    }
}
