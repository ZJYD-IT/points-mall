package com.demo.points.repository;

import com.demo.points.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ProductRepository extends JpaRepository<Product, Long> {

    List<Product> findByStatusOrderBySortNoDescIdDesc(short status);

    List<Product> findAllByOrderByStatusDescSortNoDescIdDesc();

    /**
     * 原子扣库存：一条 SQL 同时完成「判断够不够」和「扣减」，
     * 并发下不会有"读的时候还有、写的时候没了"的丢失更新。
     * 返回 0 表示库存不足或商品已下架。
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update Product p
               set p.stock = p.stock - :qty
             where p.id = :id
               and p.status = 1
               and p.stock >= :qty
            """)
    int deductStock(@Param("id") Long id, @Param("qty") int qty);
}
