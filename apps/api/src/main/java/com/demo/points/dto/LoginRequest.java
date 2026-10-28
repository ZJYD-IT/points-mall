package com.demo.points.dto;

import jakarta.validation.constraints.NotBlank;

/** account：后台=用户名，客户端=手机号 */
public record LoginRequest(
        @NotBlank(message = "账号不能为空") String account,
        @NotBlank(message = "密码不能为空") String password) {
}
