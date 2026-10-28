package com.demo.points.service;

import com.demo.points.common.BizException;
import com.demo.points.dto.RedeemRequest;
import com.demo.points.dto.RedeemResult;
import com.demo.points.entity.AppUser;
import com.demo.points.entity.PointsLedger;
import com.demo.points.entity.Product;
import com.demo.points.entity.RedeemOrder;
import com.demo.points.repository.AppUserRepository;
import com.demo.points.repository.PointsLedgerRepository;
import com.demo.points.repository.ProductRepository;
import com.demo.points.repository.RedeemOrderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 兑换流程。三个关键点：
 *
 * 1) 幂等：同一 (user, idempotencyKey) 只会产生一单。
 *    先在事务里查一次，查不到才继续；并发下两个请求都查不到时，
 *    由 redeem_order 的唯一约束兜底 —— 后者会让整笔事务回滚（积分/库存自动退回），
 *    返回 409，前端用同一个幂等键重试即可拿到已有订单。
 *
 * 2) 不超卖 / 不透支：库存和积分都用「条件更新」一条 SQL 完成，
 *    where stock >= :qty / points >= :total 保证判断和扣减是原子的。
 *
 * 3) 一致性：扣库存、扣积分、写订单、写流水在同一个事务里，要么全成要么全回滚。
 */
@Service
public class RedeemService {

    private static final Logger log = LoggerFactory.getLogger(RedeemService.class);
    private static final DateTimeFormatter TS = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final AppUserRepository userRepo;
    private final ProductRepository productRepo;
    private final RedeemOrderRepository orderRepo;
    private final PointsLedgerRepository ledgerRepo;

    public RedeemService(AppUserRepository userRepo, ProductRepository productRepo,
                         RedeemOrderRepository orderRepo, PointsLedgerRepository ledgerRepo) {
        this.userRepo = userRepo;
        this.productRepo = productRepo;
        this.orderRepo = orderRepo;
        this.ledgerRepo = ledgerRepo;
    }

    @Transactional
    public RedeemResult redeem(long userId, RedeemRequest req) {
        // ---------- 1. 幂等：命中已有单，直接返回（不重复扣）----------
        var existing = orderRepo.findByUserIdAndIdempotencyKey(userId, req.idempotencyKey());
        if (existing.isPresent()) {
            RedeemOrder o = existing.get();
            log.info("幂等命中 user={} key={} order={}", userId, req.idempotencyKey(), o.getOrderNo());
            return new RedeemResult(o.getId(), o.getOrderNo(), o.getTotalPoints(),
                    currentPoints(userId), true);
        }

        // ---------- 2. 商品校验 ----------
        Product p = productRepo.findById(req.productId())
                .orElseThrow(() -> new BizException("商品不存在"));
        if (!p.isOnSale()) {
            throw new BizException("商品已下架");
        }
        if (p.getStock() < req.quantity()) {
            throw new BizException("库存不足，仅剩 " + p.getStock() + " 件");
        }
        long total = p.getPointsCost() * req.quantity();

        // ---------- 3. 原子扣库存（防超卖）----------
        if (productRepo.deductStock(p.getId(), req.quantity()) == 0) {
            throw new BizException("库存不足，可能刚被抢完了");
        }

        // ---------- 4. 原子扣积分（防透支）----------
        if (userRepo.deductPoints(userId, total) == 0) {
            throw new BizException("积分不足，需要 " + total + " 积分");
        }
        long balanceAfter = currentPoints(userId);

        // ---------- 5. 写订单（唯一约束在这里兜底并发重复）----------
        RedeemOrder order = new RedeemOrder();
        order.setOrderNo(newOrderNo());
        order.setUserId(userId);
        order.setProductId(p.getId());
        order.setProductName(p.getName());
        order.setPointsCost(p.getPointsCost());
        order.setQuantity(req.quantity());
        order.setTotalPoints(total);
        order.setIdempotencyKey(req.idempotencyKey());
        order.setStatus("CREATED");
        order.setReceiver(req.receiver());
        order.setPhone(req.phone());
        order.setAddress(req.address());
        order.setRemark(req.remark());
        order = orderRepo.saveAndFlush(order);

        // ---------- 6. 写积分流水（只增不改，可对账）----------
        PointsLedger ledger = new PointsLedger();
        ledger.setUserId(userId);
        ledger.setDelta(-total);
        ledger.setBalanceAfter(balanceAfter);
        ledger.setBizType("REDEEM");
        ledger.setBizId(order.getOrderNo());
        ledger.setRemark("兑换 " + p.getName() + " ×" + req.quantity());
        ledgerRepo.save(ledger);

        log.info("兑换成功 user={} order={} points={} balance={}",
                userId, order.getOrderNo(), total, balanceAfter);
        return new RedeemResult(order.getId(), order.getOrderNo(), total, balanceAfter, false);
    }

    private long currentPoints(long userId) {
        return userRepo.findById(userId).map(AppUser::getPoints)
                .orElseThrow(() -> new BizException("用户不存在"));
    }

    private String newOrderNo() {
        return "RM" + TS.format(LocalDateTime.now())
                + ThreadLocalRandom.current().nextInt(1000, 10000);
    }
}
