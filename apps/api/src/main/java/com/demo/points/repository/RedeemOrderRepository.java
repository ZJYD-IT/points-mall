package com.demo.points.repository;

import com.demo.points.entity.RedeemOrder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RedeemOrderRepository extends JpaRepository<RedeemOrder, Long> {

    /** 幂等查询：同一用户 + 同一幂等键 */
    Optional<RedeemOrder> findByUserIdAndIdempotencyKey(Long userId, String idempotencyKey);

    List<RedeemOrder> findByUserIdOrderByIdDesc(Long userId);

    List<RedeemOrder> findAllByOrderByIdDesc();
}
