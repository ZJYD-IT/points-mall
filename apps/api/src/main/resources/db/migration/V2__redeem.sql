-- Phase 2：积分商品 + 兑换单

create table product (
    id          bigserial primary key,
    name        varchar(120) not null,
    image_url   varchar(500),
    description varchar(500),
    -- 兑换所需积分（单价）
    points_cost bigint       not null check (points_cost > 0),
    -- 库存
    stock       int          not null default 0 check (stock >= 0),
    -- 1=上架 0=下架
    status      smallint     not null default 1,
    sort_no     int          not null default 0,
    created_at  timestamptz  not null default now()
);
create index idx_product_status on product(status, sort_no desc, id desc);

create table redeem_order (
    id              bigserial primary key,
    order_no        varchar(32)  not null unique,
    user_id         bigint       not null references app_user(id),
    product_id      bigint       not null references product(id),
    -- 下面是下单时的快照：商品改名/调价不影响历史单
    product_name    varchar(120) not null,
    points_cost     bigint       not null,
    quantity        int          not null check (quantity > 0),
    total_points    bigint       not null,
    -- 幂等键：同一用户 + 同一键只允许一单
    idempotency_key varchar(64)  not null,
    status          varchar(20)  not null default 'CREATED',
    receiver        varchar(50),
    phone           varchar(20),
    address         varchar(300),
    remark          varchar(200),
    created_at      timestamptz  not null default now(),
    constraint uk_redeem_idem unique (user_id, idempotency_key)
);
create index idx_redeem_user   on redeem_order(user_id, id desc);
create index idx_redeem_status on redeem_order(status, id desc);

-- 演示商品
insert into product (name, description, points_cost, stock, status, sort_no) values
  ('星巴克中杯券',   '全国门店通用，有效期 90 天',        800,  50, 1, 100),
  ('定制帆布袋',     '加厚帆布，可印 LOGO',               300, 200, 1, 90),
  ('保温杯 500ml',   '316 不锈钢，24 小时保温',          1200,  30, 1, 80),
  ('数据线 1m',      'Type-C 快充线',                    150, 500, 1, 70),
  ('限量版徽章',     '数量有限，兑完即止',               2000,   0, 1, 60),
  ('已下架测试商品', '用来验证下架商品不能兑换',          100, 100, 0, 10);
