# ---- 构建阶段 ----
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
# 先只拷 pom 拿依赖，利用 Docker 层缓存：改代码不会重新下载依赖
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .
RUN ./mvnw -B -q dependency:go-offline || true
COPY src ./src
RUN ./mvnw -B -q clean package -DskipTests

# ---- 运行阶段 ----
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=build /build/target/*.jar app.jar
USER app
EXPOSE 8080
# 用 MaxRAMPercentage 而不是写死 -Xmx，容器给多少内存就按比例用
ENTRYPOINT ["java","-XX:MaxRAMPercentage=60","-jar","app.jar"]
