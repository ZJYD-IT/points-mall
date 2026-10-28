package com.demo.points.security;

import com.demo.points.common.BizException;
import org.springframework.security.core.Authentication;

/** JWT subject 形如 "user:1" / "admin:1" */
public final class CurrentUser {

    private CurrentUser() {}

    public static long id(Authentication auth) {
        String name = auth == null ? null : auth.getName();
        if (name == null || !name.contains(":")) {
            throw new BizException("未登录", 401);
        }
        return Long.parseLong(name.substring(name.indexOf(':') + 1));
    }
}
