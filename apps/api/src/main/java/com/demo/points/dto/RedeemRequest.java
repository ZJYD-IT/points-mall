package com.demo.points.dto;

import jakarta.validation.constraints.*;

public record RedeemRequest(
        @NotNull Long productId,
        @NotNull @Min(1) @Max(99) Integer quantity,
        @Size(max = 50) String receiver,
        @Size(max = 20) String phone,
        @Size(max = 300) String address,
        @Size(max = 200) String remark,
        /** 幂等键：由前端生成，同一单重复提交必须相同 */
        @NotBlank @Size(max = 64) String idempotencyKey) {
}
