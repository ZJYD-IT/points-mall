package com.demo.points.repository;

import com.demo.points.entity.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {

    Optional<AppUser> findByPhone(String phone);

    /**
     * 原子扣积分：where points >= 保证绝不扣成负数。
     * 返回 0 表示积分不够。
     * clearAutomatically=true 让持久化上下文失效，否则紧接着读出来的还是扣之前的旧值。
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update AppUser u
               set u.points = u.points - :points,
                   u.version = u.version + 1
             where u.id = :id
               and u.points >= :points
            """)
    int deductPoints(@Param("id") Long id, @Param("points") long points);
}
