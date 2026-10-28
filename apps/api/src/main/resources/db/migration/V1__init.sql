-- 积分商城 · 初始化（只建表，演示数据由 DataSeeder 在启动时用 PasswordEncoder 生成）
-- 约定：积分/数量用 bigint，时间用 timestamptz

create table admin_user (
    id            bigserial primary key,
    username      varchar(50)  not null unique,
    password_hash varchar(100) not null,
    role          varchar(20)  not null default 'ADMIN',
    enabled       boolean      not null default true,
    created_at    timestamptz  not null default now()
);

create table app_user (
    id            bigserial primary key,
    phone         varchar(20)  not null unique,
    nickname      varchar(50),
    password_hash varchar(100) not null,
    -- 积分余额是冗余字段：任何变动都要在同一个事务里同时写 points_ledger，
    -- 并用 @Version 乐观锁防并发覆盖
    points        bigint       not null default 0 check (points >= 0),
    version       bigint       not null default 0,
    enabled       boolean      not null default true,
    created_at    timestamptz  not null default now()
);

-- 积分流水：只增不改，余额可用它全量对账
create table points_ledger (
    id            bigserial primary key,
    user_id       bigint      not null references app_user(id),
    delta         bigint      not null,
    balance_after bigint      not null,
    biz_type      varchar(30) not null,
    biz_id        varchar(64),
    remark        varchar(200),
    created_at    timestamptz not null default now()
);

create index idx_points_ledger_user on points_ledger(user_id, id desc);
