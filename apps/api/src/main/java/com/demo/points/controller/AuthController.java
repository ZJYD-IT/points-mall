package com.demo.points.controller;

import com.demo.points.common.BizException;
import com.demo.points.dto.LoginRequest;
import com.demo.points.dto.LoginResponse;
import com.demo.points.entity.AdminUser;
import com.demo.points.entity.AppUser;
import com.demo.points.repository.AdminUserRepository;
import com.demo.points.repository.AppUserRepository;
import com.demo.points.security.JwtService;
import jakarta.validation.Valid;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AdminUserRepository adminRepo;
    private final AppUserRepository userRepo;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    public AuthController(AdminUserRepository adminRepo, AppUserRepository userRepo,
                          PasswordEncoder encoder, JwtService jwt) {
        this.adminRepo = adminRepo;
        this.userRepo = userRepo;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    /** 后台登录 */
    @PostMapping("/admin/login")
    public LoginResponse adminLogin(@Valid @RequestBody LoginRequest req) {
        AdminUser admin = adminRepo.findByUsername(req.account())
                .orElseThrow(() -> new BizException("账号或密码错误", 401));
        if (!admin.isEnabled() || !encoder.matches(req.password(), admin.getPasswordHash())) {
            throw new BizException("账号或密码错误", 401);
        }
        String token = jwt.issue("admin:" + admin.getId(), "ADMIN");
        return new LoginResponse(token, "ADMIN", admin.getId(), admin.getUsername(), null);
    }

    /** 客户端登录（手机号） */
    @PostMapping("/user/login")
    public LoginResponse userLogin(@Valid @RequestBody LoginRequest req) {
        AppUser user = userRepo.findByPhone(req.account())
                .orElseThrow(() -> new BizException("手机号或密码错误", 401));
        if (!user.isEnabled() || !encoder.matches(req.password(), user.getPasswordHash())) {
            throw new BizException("手机号或密码错误", 401);
        }
        String token = jwt.issue("user:" + user.getId(), "USER");
        return new LoginResponse(token, "USER", user.getId(),
                user.getNickname() == null ? user.getPhone() : user.getNickname(), user.getPoints());
    }
}
