package com.paperrabbit.backend.dto;

public record CitationGraphEdgeDto(
		String sourceId,
		String targetId,
		String relation) {
}
