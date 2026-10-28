package com.demo.points.controller;

import com.demo.points.dto.OrderView;
import com.demo.points.repository.RedeemOrderRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** 后台兑换单列表：需要 ROLE_ADMIN */
@RestController
@RequestMapping("/admin/orders")
public class AdminOrderController {

    private final RedeemOrderRepository orderRepo;

    public AdminOrderController(RedeemOrderRepository orderRepo) {
        this.orderRepo = orderRepo;
    }

    @GetMapping
    public List<OrderView> list() {
        return orderRepo.findAllByOrderByIdDesc().stream().map(OrderView::of).toList();
    }
}
