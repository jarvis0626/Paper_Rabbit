package com.paperrabbit.backend.config;

import java.net.URI;
import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("paper-rabbit.openalex")
public record OpenAlexProperties(
		URI baseUrl,
		String apiKey,
		Duration connectTimeout,
		Duration readTimeout,
		int maxAttempts,
		Duration initialBackoff) {

	public OpenAlexProperties {
		if (baseUrl == null) {
			baseUrl = URI.create("https://api.openalex.org");
		}
		apiKey = apiKey == null ? "" : apiKey.trim();
		connectTimeout = connectTimeout == null ? Duration.ofSeconds(5) : connectTimeout;
		readTimeout = readTimeout == null ? Duration.ofSeconds(20) : readTimeout;
		maxAttempts = Math.max(1, maxAttempts);
		initialBackoff = initialBackoff == null ? Duration.ofMillis(250) : initialBackoff;
	}
}
