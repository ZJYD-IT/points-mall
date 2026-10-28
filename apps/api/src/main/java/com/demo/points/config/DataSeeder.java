package com.demo.points.config;

import com.demo.points.entity.AdminUser;
import com.demo.points.entity.AppUser;
import com.demo.points.repository.AdminUserRepository;
import com.demo.points.repository.AppUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * 启动时确保存在演示账号。
 * 不用 SQL 里写死 BCrypt 串：那样密码对不对只能靠猜，这里由 PasswordEncoder 生成，一定匹配。
 * 生产环境请通过环境变量关掉（见 README）。
 */
@Component
public class DataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final AdminUserRepository adminRepo;
    private final AppUserRepository userRepo;
    private final PasswordEncoder encoder;

    public DataSeeder(AdminUserRepository adminRepo, AppUserRepository userRepo, PasswordEncoder encoder) {
        this.adminRepo = adminRepo;
        this.userRepo = userRepo;
        this.encoder = encoder;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (adminRepo.findByUsername("admin").isEmpty()) {
            AdminUser a = new AdminUser();
            a.setUsername("admin");
            a.setPasswordHash(encoder.encode("admin123"));
            a.setRole("ADMIN");
            adminRepo.save(a);
            log.warn("已创建演示管理员 admin / admin123 —— 上线前请修改或删除");
        }
        if (userRepo.findByPhone("13800000000").isEmpty()) {
            AppUser u = new AppUser();
            u.setPhone("13800000000");
            u.setNickname("测试用户");
            u.setPasswordHash(encoder.encode("123456"));
            u.setPoints(1000);
            userRepo.save(u);
            log.warn("已创建演示用户 13800000000 / 123456，初始积分 1000");
        }
    }
}
