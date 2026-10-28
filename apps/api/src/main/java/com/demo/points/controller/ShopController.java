package com.demo.points.controller;

import com.demo.points.common.BizException;
import com.demo.points.dto.*;
import com.demo.points.entity.AppUser;
import com.demo.points.repository.AppUserRepository;
import com.demo.points.repository.PointsLedgerRepository;
import com.demo.points.repository.RedeemOrderRepository;
import com.demo.points.security.CurrentUser;
import com.demo.points.service.ProductService;
import com.demo.points.service.RedeemService;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 客户端接口：需要 ROLE_USER */
@RestController
@RequestMapping("/shop")
public class ShopController {

    private final ProductService productService;
    private final RedeemService redeemService;
    private final AppUserRepository userRepo;
    private final RedeemOrderRepository orderRepo;
    private final PointsLedgerRepository ledgerRepo;

    public ShopController(ProductService productService, RedeemService redeemService,
                          AppUserRepository userRepo, RedeemOrderRepository orderRepo,
                          PointsLedgerRepository ledgerRepo) {
        this.productService = productService;
        this.redeemService = redeemService;
        this.userRepo = userRepo;
        this.orderRepo = orderRepo;
        this.ledgerRepo = ledgerRepo;
    }

    /** 我的信息（含积分余额） */
    @GetMapping("/me")
    public MeView me(Authentication auth) {
        long uid = CurrentUser.id(auth);
        AppUser u = userRepo.findById(uid).orElseThrow(() -> new BizException("用户不存在", 401));
        return new MeView(u.getId(), u.getPhone(), u.getNickname(), u.getPoints());
    }

    /** 上架商品列表 */
    @GetMapping("/products")
    public List<ProductView> products() {
        return productService.listOnSale().stream().map(ProductView::of).toList();
    }

    /** 兑换 */
    @PostMapping("/redeem")
    public RedeemResult redeem(Authentication auth, @Valid @RequestBody RedeemRequest req) {
        return redeemService.redeem(CurrentUser.id(auth), req);
    }

    /** 我的兑换单 */
    @GetMapping("/orders")
    public List<OrderView> orders(Authentication auth) {
        return orderRepo.findByUserIdOrderByIdDesc(CurrentUser.id(auth))
                .stream().map(OrderView::of).toList();
    }

    /** 我的积分明细 */
    @GetMapping("/ledger")
    public List<LedgerView> ledger(Authentication auth) {
        return ledgerRepo.findByUserIdOrderByIdDesc(CurrentUser.id(auth))
                .stream().map(LedgerView::of).toList();
    }
}
