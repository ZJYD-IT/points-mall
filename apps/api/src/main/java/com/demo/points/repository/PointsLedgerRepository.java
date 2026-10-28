package com.demo.points.repository;

import com.demo.points.entity.PointsLedger;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PointsLedgerRepository extends JpaRepository<PointsLedger, Long> {
    List<PointsLedger> findByUserIdOrderByIdDesc(Long userId);
}
