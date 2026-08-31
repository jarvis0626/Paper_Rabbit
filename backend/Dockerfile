FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw --batch-mode dependency:go-offline

COPY src src
RUN ./mvnw --batch-mode -DskipTests package

FROM eclipse-temurin:21-jre

RUN useradd --system --uid 10001 --user-group paper-rabbit
WORKDIR /app
COPY --from=build /workspace/target/app.jar app.jar
COPY docker-entrypoint.sh /usr/local/bin/paper-rabbit-entrypoint
RUN chmod +x /usr/local/bin/paper-rabbit-entrypoint \
    && chown -R paper-rabbit:paper-rabbit /app

USER paper-rabbit
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/paper-rabbit-entrypoint"]
