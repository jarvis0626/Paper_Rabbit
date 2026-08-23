package com.paperrabbit.backend.dto;

public record TopicDto(
		String id,
		String name,
		double score,
		String field,
		String subfield) {
}
