package com.demo.points.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ProductSaveRequest(
        @NotBlank @Size(max = 120) String name,
        @Size(max = 500) String imageUrl,
        @Size(max = 500) String description,
        @NotNull @Min(1) Long pointsCost,
        @NotNull @Min(0) Integer stock,
        /** 1=上架 0=下架，不传默认上架 */
        Short status,
        Integer sortNo) {
}
